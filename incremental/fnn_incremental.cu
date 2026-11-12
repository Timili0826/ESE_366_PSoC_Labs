// Compile the final Opt3 implementation directly; do not fork/copy its kernels.
#define main opt3_original_main
#include "../cuda_03_register_reuse/fnn_cuda_opt3.cu"
#undef main
#include "checkpoint.hpp"
namespace inc {
using checkpoint::State;
using checkpoint::require;
static void capture(GpuNetwork& g,State& s) {
    CUDA(cudaDeviceSynchronize());s.weights.clear();s.biases.clear();
    for(auto& l:g.layers){s.weights.push_back(l.w.read(l.w.count));s.biases.push_back(l.b.read(l.b.count));}
}
static void restore(GpuNetwork& g,const State& s) {
    checkpoint::validate(s);
    for(size_t l=0;l<g.layers.size();++l){g.layers[l].w.upload(s.weights[l].data(),s.weights[l].size());g.layers[l].b.upload(s.biases[l].data(),s.biases[l].size());}
}
static bool same_parameters(const State& a,const State& b){return a.weights==b.weights && a.biases==b.biases;}
static void warmup(GpuNetwork& g,const DeviceDataset& d,const Buffer<int>& ids,int count) {
    State before,after;capture(g,before);
    gather(g,d,ids.p,0,std::min(count,g.capacity));g.forward(std::min(count,g.capacity));g.loss(std::min(count,g.capacity));g.backward(std::min(count,g.capacity));
    CUDA(cudaDeviceSynchronize());capture(g,after);require(same_parameters(before,after),"Warm-up modified model parameters");
}
static uint64_t data_tag(const HostData& h) {
    uint64_t tag=14695981039346656037ull;
    auto add=[&](const unsigned char* p,size_t n){for(size_t i=0;i<n;++i){tag^=p[i];tag*=1099511628211ull;}};
    for(const auto* d:{&h.train,&h.test}){
        add(reinterpret_cast<const unsigned char*>(d->images),static_cast<size_t>(d->count)*d->rows*d->cols*sizeof(float));
        add(d->labels,d->count);
    }return tag;
}
static void ids_csv(const std::string& path,const State& s) {
    std::ofstream f(path);require(bool(f),"Cannot create sample IDs");f<<"dataset,sample_id,subset\n";
    for(const auto* ids:{&s.initial_ids,&s.new_ids,&s.val_ids}){
        const char* subset=ids==&s.initial_ids?"initial_40000":ids==&s.new_ids?"new_8000":"validation_12000";
        for(int id:*ids)f<<"train,"<<id<<','<<subset<<'\n';
    }
    for(int id=0;id<10000;++id)f<<"test,"<<id<<",test_10000\n";
    require(bool(f),"Writing sample IDs failed");
}
static void create_fresh(const std::string& path) {
    require(!path.empty(),"Empty output directory");
    if(mkdir(path.c_str(),0755))throw std::runtime_error("Output directory must be new and its parent must exist: "+path);
}
// Synthetic GPU test: all operations use the fixed optimized network and FP32 SGD.
static void tiny_input(GpuNetwork& g,const std::vector<int>& order) {
    std::vector<float>x(order.size()*784);std::vector<unsigned char>y(order.size());
    for(size_t i=0;i<order.size();++i){y[i]=static_cast<unsigned char>(order[i]%10);for(int j=0;j<784;++j)x[i*784+j]=float((order[i]*17+j*3)%101)/101.0f;}
    g.input.upload(x.data(),x.size());g.labels.upload(y.data(),y.size());
}
static void tiny_epochs(GpuNetwork& g,State& s,int n) {
    for(int e=0;e<n;++e){
        dataset_shuffle_indices(s.order.data(),static_cast<int>(s.order.size()),&s.rng);
        for(size_t pos=0;pos<s.order.size();pos+=32){
            size_t end=std::min(pos+32,s.order.size());std::vector<int> batch(s.order.begin()+pos,s.order.begin()+end);
            tiny_input(g,batch);int actual=static_cast<int>(batch.size());g.forward(actual);g.loss(actual);g.backward(actual);g.update(actual,s.lr);++s.updates;
        }
        ++s.epoch;
    }
    capture(g,s);
}
static int self_check(const std::string& out) {
    create_fresh(out);
    bool numerical=check_case({784,128,64,10},32,7,128,16,GemmPolicy::Targeted,true,2);
    require(numerical,"Opt3 CPU/GPU numerical check failed");
    CpuNetwork cpu({784,128,64,10},39);GpuNetwork a(cpu.n,32,128,16,GemmPolicy::Targeted,true,2),b(cpu.n,32,128,16,GemmPolicy::Targeted,true,2),c(cpu.n,32,128,16,GemmPolicy::Targeted,true,2);
    State initial;for(int i=0;i<71;++i)initial.initial_ids.push_back(i);initial.new_ids={71,72};initial.val_ids={73,74};initial.order=initial.initial_ids;
    State continuous=initial,partial=initial;tiny_epochs(a,continuous,3);tiny_epochs(b,partial,1);
    std::vector<int> probe(partial.order.begin(),partial.order.begin()+7);tiny_input(b,probe);b.forward(7);b.loss(7);auto logits=b.layers.back().output.read(70),loss=b.losses.read(7);
    State prewarm=partial; b.backward(7);CUDA(cudaDeviceSynchronize());capture(b,partial);require(same_parameters(prewarm,partial),"Warmup backward changed parameters");
    checkpoint::save(out+"/roundtrip.ckpt",partial);State loaded=checkpoint::load(out+"/roundtrip.ckpt");restore(c,loaded);
    require(same_parameters(partial,loaded),"Checkpoint parameter roundtrip failed");
    tiny_input(c,probe);c.forward(7);c.loss(7);
    require(logits==c.layers.back().output.read(70) && loss==c.losses.read(7),"Reload logits/loss mismatch");
    tiny_epochs(c,loaded,2);
    require(same_parameters(continuous,loaded) && continuous.rng==loaded.rng && continuous.order==loaded.order && continuous.updates==loaded.updates && continuous.epoch==loaded.epoch,"Continuous versus resumed GPU training mismatch");
    std::ofstream f(out+"/PASS.txt");f<<"PASS: CPU/GPU numerical reference; warm-up no update; exact parameter/logits/loss roundtrip; continuous 3 epochs equals 1 + checkpoint + 2 epochs.\n";
    require(bool(f),"Cannot save check result");std::cout<<"Incremental GPU checks: PASS\n";return 0;
}
static int run(int argc,char** argv) {
    require(argc==5 || argc==6,"Usage: fnn_incremental initial|new|resume DATA NEW_OUTPUT EPOCHS [LOAD_CHECKPOINT]");
    std::string mode=argv[1],dir=argv[2],out=argv[3];int epochs=positive_int(argv[4],"epochs");
    require(mode=="initial" || mode=="new" || mode=="resume","Invalid mode");
    require((mode=="initial" && argc==5) || (mode!="initial" && argc==6),"Checkpoint argument mismatch");
    const auto process_start=Clock::now();HostData h;
    auto path=[&](const char* p){return dir+"/"+p;};
    require(!dataset_load_mnist(&h.train,path("train-images-idx3-ubyte").c_str(),path("train-labels-idx1-ubyte").c_str()),"Training data load failed");
    require(!dataset_load_mnist(&h.test,path("t10k-images-idx3-ubyte").c_str(),path("t10k-labels-idx1-ubyte").c_str()),"Test data load failed");
    require(h.train.count==60000 && h.test.count==10000 && h.train.rows==28 && h.train.cols==28 && h.test.rows==28 && h.test.cols==28,"Expected full MNIST dataset");
    int ntrain=0;require(!dataset_split_indices(60000,0.8f,39,&h.indices,&ntrain) && ntrain==48000,"Split failed");
    State canonical;canonical.initial_ids.assign(h.indices,h.indices+40000);canonical.new_ids.assign(h.indices+40000,h.indices+48000);canonical.val_ids.assign(h.indices+48000,h.indices+60000);canonical.order=canonical.initial_ids;canonical.dataset_tag=data_tag(h);
    State state=mode=="initial"?canonical:checkpoint::load(argv[5]);
    require(state.initial_ids==canonical.initial_ids && state.new_ids==canonical.new_ids && state.val_ids==canonical.val_ids && state.dataset_tag==canonical.dataset_tag,"Checkpoint dataset/split provenance mismatch");
        if(mode!="initial"){
        const uint64_t expected=state.phase==1?uint64_t(state.epoch)*1250:12500+uint64_t(state.epoch)*250;
        require(state.updates==expected,"Checkpoint epoch/update count mismatch");
    }
    if(mode=="new"){
        require(state.phase==1 && state.epoch==10 && state.updates==12500,"New-data stage requires completed 40000 x 10 initial stage");
        state.phase=2;state.epoch=0;state.rng=40;state.order=state.new_ids;
    }
    // Constructors initialize scratch storage, then every loaded parameter is replaced before use.
    CpuNetwork cpu({784,128,64,10},39);GpuNetwork gpu(cpu.n,32,128,16,GemmPolicy::Targeted,true,2);
    if(mode!="initial")restore(gpu,state);
    DeviceDataset train_data(h.train),test_data(h.test);Buffer<int> order(state.order.size()),val(state.val_ids.size());
    order.upload(state.order.data(),state.order.size());val.upload(state.val_ids.data(),state.val_ids.size());
    create_fresh(out);ids_csv(out+"/sample_ids.csv",state);
    std::ofstream csv(out+"/metrics.csv"),info(out+"/run_info.txt");require(bool(csv)&&bool(info),"Cannot create results");
    info<<"implementation=incremental final Opt3 FP32\nmode="<<mode<<"\nphase="<<state.phase<<"\narchitecture=784,128,64,10\nseed=39\nlr=0.01\nbatch=32\nthreads=128\ntile=16\ngemm_policy=targeted\nforward_fusion=on\ndw1_rows_per_thread=2\noptimizer=SGD_no_momentum\nprofiler=none\nactive_train_count="<<state.order.size()<<"\nval_count=12000\ntest_count=10000\nepochs_requested="<<epochs<<"\ncheckpoint_source="<<(mode=="initial"?"none":argv[5])<<"\ndataset_tag="<<state.dataset_tag<<'\n';
    csv<<"phase,phase_epoch,event,active_train_count,total_updates,train_loss,train_accuracy,val_loss,val_accuracy,train_gpu_ms,eval_wall_s,epoch_wall_s,cumulative_epoch_wall_s\n";
    csv<<std::setprecision(12);
    // This pre-update evaluation is deliberately outside epoch timing.
    Metrics loaded_val=evaluate(gpu,train_data,val.p,0,12000);CUDA(cudaDeviceSynchronize());
    csv<<state.phase<<','<<state.epoch<<",loaded_before_update,"<<state.order.size()<<','<<state.updates<<",,,"<<loaded_val.loss<<','<<loaded_val.accuracy<<",0,0,0,"<<state.cumulative_wall_s<<'\n';csv.flush();
    info<<"pre_update_validation_loss="<<loaded_val.loss<<"\npre_update_validation_accuracy="<<loaded_val.accuracy<<'\n';
    warmup(gpu,train_data,order,static_cast<int>(state.order.size()));
    Event start,stop;const uint64_t updates_at_start=state.updates;double train_gpu_total=0,epoch_total=0;
    for(int e=0;e<epochs;++e){
        const auto t=Clock::now();dataset_shuffle_indices(state.order.data(),static_cast<int>(state.order.size()),&state.rng);order.upload(state.order.data(),state.order.size());
        CUDA(cudaEventRecord(start.e));
        for(int pos=0;pos<static_cast<int>(state.order.size());pos+=32){int actual=std::min(32,static_cast<int>(state.order.size())-pos);gather(gpu,train_data,order.p,pos,actual);gpu.forward(actual);gpu.loss(actual);gpu.backward(actual);gpu.update(actual,state.lr);++state.updates;}
        CUDA(cudaEventRecord(stop.e));CUDA(cudaEventSynchronize(stop.e));float ms=0;CUDA(cudaEventElapsedTime(&ms,start.e,stop.e));train_gpu_total+=ms/1000;
        auto ev=Clock::now();Metrics tr=evaluate(gpu,train_data,order.p,0,static_cast<int>(state.order.size()));Metrics va=evaluate(gpu,train_data,val.p,0,12000);CUDA(cudaDeviceSynchronize());double eval_s=seconds(ev),wall=seconds(t);state.cumulative_wall_s+=wall;epoch_total+=wall;++state.epoch;
        csv<<state.phase<<','<<state.epoch<<",epoch_end,"<<state.order.size()<<','<<state.updates<<','<<tr.loss<<','<<tr.accuracy<<','<<va.loss<<','<<va.accuracy<<','<<ms<<','<<eval_s<<','<<wall<<','<<state.cumulative_wall_s<<'\n';csv.flush();require(bool(csv),"Metric write failed");
        std::cout<<"phase "<<state.phase<<" epoch "<<state.epoch<<" val_acc "<<100*va.accuracy<<" epoch_wall_s "<<wall<<'\n';
        capture(gpu,state);std::string ckpt=out+"/epoch_"+std::to_string(state.epoch)+".ckpt";checkpoint::save(ckpt,state);info<<"checkpoint="<<ckpt<<'\n';info.flush();require(bool(info),"Info write failed");
    }
    // No initial-stage final test: held out until the end of the new-data phase.
    if(state.phase==2){auto t=Clock::now();Metrics test=evaluate(gpu,test_data,nullptr,0,10000);CUDA(cudaDeviceSynchronize());info<<"final_test_loss="<<test.loss<<"\nfinal_test_accuracy="<<test.accuracy<<"\nfinal_test_wall_s="<<seconds(t)<<'\n';}
    info<<"updates_this_process="<<state.updates-updates_at_start<<"\ntrain_gpu_s="<<train_gpu_total<<"\nepoch_wall_sum_s="<<epoch_total<<"\nprocess_wall_s_before_cleanup="<<seconds(process_start)<<"\ncompleted=true\n";info.flush();require(bool(info),"Writing info failed");
    return 0;
}
}
int main(int argc,char** argv){
    try{
        std::cout<<std::unitbuf;int device=0;CUDA(cudaGetDevice(&device));cudaDeviceProp p{};CUDA(cudaGetDeviceProperties(&p,device));
        std::cout<<"GPU "<<p.name<<" CC "<<p.major<<'.'<<p.minor<<'\n';
        if(argc==3 && std::string(argv[1])=="--check")return inc::self_check(argv[2]);
        return inc::run(argc,argv);
    }catch(const std::exception& e){std::cerr<<"ERROR: "<<e.what()<<'\n';return 1;}
}