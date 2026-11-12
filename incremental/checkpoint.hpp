#ifndef FNN_CHECKPOINT_HPP
#define FNN_CHECKPOINT_HPP
// Portable little-endian FP32 format; SGD has no momentum/optimizer buffers.
#include <algorithm>
#include <cerrno>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <limits>
#include <stdexcept>
#include <string>
#include <vector>
#include <fcntl.h>
#include <sys/stat.h>
#ifdef _WIN32
#include <io.h>
#else
#include <unistd.h>
#endif
namespace checkpoint {
struct State {
    uint32_t phase=1, epoch=0, rng=40, seed=39, batch=32;
    uint32_t threads=128, tile=16, rows=2, fusion=1, policy=1;
    uint64_t updates=0, dataset_tag=0;
    double cumulative_wall_s=0;
    float lr=0.01f;
    std::vector<uint32_t> widths{784,128,64,10};
    std::vector<int> initial_ids, new_ids, val_ids, order;
    std::vector<std::vector<float>> weights, biases; // GPU layout W[in,out]
};
inline void require(bool ok, const char* message) { if (!ok) throw std::runtime_error(message); }
inline uint64_t hash(const unsigned char* p, size_t n) {
    uint64_t h=14695981039346656037ull;
    for(size_t i=0;i<n;++i) { h^=p[i]; h*=1099511628211ull; }
    return h;
}
inline void u32(std::vector<unsigned char>& b,uint32_t x) { for(int i=0;i<4;++i)b.push_back(static_cast<unsigned char>(x>>(8*i))); }
inline void u64(std::vector<unsigned char>& b,uint64_t x) { for(int i=0;i<8;++i)b.push_back(static_cast<unsigned char>(x>>(8*i))); }
inline void f32(std::vector<unsigned char>& b,float x) { uint32_t t; std::memcpy(&t,&x,4); u32(b,t); }
inline void f64(std::vector<unsigned char>& b,double x) { uint64_t t; std::memcpy(&t,&x,8); u64(b,t); }
inline void validate(const State& s) {
    require(sizeof(float)==4 && std::numeric_limits<float>::is_iec559,"FP32 required");
    require(s.widths==std::vector<uint32_t>({784,128,64,10}),"Checkpoint shape mismatch");
    require(s.phase==1 || s.phase==2,"Invalid phase");
    require(s.seed==39 && s.batch==32 && s.lr==0.01f && s.threads==128 && s.tile==16 && s.rows==2 && s.fusion==1 && s.policy==1,"Checkpoint configuration mismatch");
    require(std::isfinite(s.cumulative_wall_s) && s.cumulative_wall_s>=0,"Invalid time");
    require(!s.initial_ids.empty() && !s.new_ids.empty() && !s.val_ids.empty(),"Empty data split");
    auto all=s.initial_ids; all.insert(all.end(),s.new_ids.begin(),s.new_ids.end()); all.insert(all.end(),s.val_ids.begin(),s.val_ids.end());
    std::sort(all.begin(),all.end());
    require(all.size()<=60000,"Too many sample IDs");
    for(size_t i=0;i<all.size();++i) require(all[i]==static_cast<int>(i),"Split IDs must be disjoint and cover training-file IDs");
    auto order=s.order, expected=s.phase==1?s.initial_ids:s.new_ids;
    std::sort(order.begin(),order.end()); std::sort(expected.begin(),expected.end());
    require(order==expected,"Active sample order mismatch");
    require(s.weights.size()==3 && s.biases.size()==3,"Missing parameter layers");
    for(size_t l=0;l<3;++l) {
        require(s.weights[l].size()==static_cast<size_t>(s.widths[l])*s.widths[l+1] && s.biases[l].size()==s.widths[l+1],"Parameter shape mismatch");
        for(float x:s.weights[l]) require(std::isfinite(x),"Nonfinite weight");
        for(float x:s.biases[l]) require(std::isfinite(x),"Nonfinite bias");
    }
}
inline std::vector<unsigned char> encode(const State& s) {
    validate(s); std::vector<unsigned char> b{'F','N','N','O','P','T','3',0};
    u32(b,1); // format version
    for(auto x:{s.phase,s.epoch,s.rng,s.seed,s.batch,s.threads,s.tile,s.rows,s.fusion,s.policy})u32(b,x);
    u64(b,s.updates); u64(b,s.dataset_tag); f64(b,s.cumulative_wall_s); f32(b,s.lr);
    u32(b,4); for(auto x:s.widths)u32(b,x);
    // Explicit optimizer code 0 means plain SGD, with no additional state.
    u32(b,0);
    u32(b,1); u32(b,1); u32(b,0); // activations: ReLU, ReLU, linear
    for(const auto* ids:{&s.initial_ids,&s.new_ids,&s.val_ids,&s.order}) {
        u32(b,static_cast<uint32_t>(ids->size())); for(int x:*ids)u32(b,static_cast<uint32_t>(x));
    }
    for(size_t l=0;l<3;++l) for(const auto* v:{&s.weights[l],&s.biases[l]}) {
        u32(b,static_cast<uint32_t>(v->size())); for(float x:*v)f32(b,x);
    }
    u64(b,hash(b.data(),b.size())); return b;
}
struct Reader {
    const std::vector<unsigned char>& b; size_t pos=0;
    uint64_t get(int n) { require(pos+static_cast<size_t>(n)<=b.size(),"Truncated checkpoint"); uint64_t v=0;for(int i=0;i<n;++i)v|=uint64_t(b[pos++])<<(8*i);return v; }
    uint32_t u32(){return static_cast<uint32_t>(get(4));}
    uint64_t u64(){return get(8);}
    float f32(){uint32_t v=u32();float x;std::memcpy(&x,&v,4);return x;}
    double f64(){uint64_t v=u64();double x;std::memcpy(&x,&v,8);return x;}
};
inline State decode(const std::vector<unsigned char>& b) {
    require(b.size()>=32 && b.size()<=4000000,"Invalid checkpoint size");
    Reader tail{b,b.size()-8}; require(tail.u64()==hash(b.data(),b.size()-8),"Checkpoint checksum mismatch");
    require(std::memcmp(b.data(),"FNNOPT3\0",8)==0,"Bad checkpoint magic");
    Reader r{b,8}; require(r.u32()==1,"Unsupported checkpoint version"); State s;
    s.phase=r.u32();s.epoch=r.u32();s.rng=r.u32();s.seed=r.u32();s.batch=r.u32();s.threads=r.u32();s.tile=r.u32();s.rows=r.u32();s.fusion=r.u32();s.policy=r.u32();
    s.updates=r.u64();s.dataset_tag=r.u64();s.cumulative_wall_s=r.f64();s.lr=r.f32();
    require(r.u32()==4,"Invalid architecture length");s.widths.clear();for(int i=0;i<4;++i)s.widths.push_back(r.u32());
    require(s.widths==std::vector<uint32_t>({784,128,64,10}),"Unsupported shape");
    require(r.u32()==0,"Unsupported optimizer");
    require(r.u32()==1 && r.u32()==1 && r.u32()==0,"Activation structure mismatch");
    for(auto* ids:{&s.initial_ids,&s.new_ids,&s.val_ids,&s.order}) {
        uint32_t n=r.u32();require(n<=60000,"Invalid ID count");ids->resize(n);for(auto& x:*ids){uint32_t id=r.u32();require(id<60000,"Invalid ID");x=static_cast<int>(id);}
    }
    s.weights.resize(3);s.biases.resize(3);
    for(size_t l=0;l<3;++l) for(auto* v:{&s.weights[l],&s.biases[l]}) {
        uint32_t n=r.u32();size_t expected=v==&s.weights[l]?static_cast<size_t>(s.widths[l])*s.widths[l+1]:s.widths[l+1];
        require(n==expected,"Invalid parameter count");v->resize(n);for(auto& x:*v)x=r.f32();
    }
    require(r.pos==b.size()-8,"Trailing checkpoint content");validate(s);return s;
}
inline State load(const std::string& path) {
    FILE* f=std::fopen(path.c_str(),"rb");require(f!=nullptr,"Cannot open checkpoint");
    if(std::fseek(f,0,SEEK_END)) {std::fclose(f);throw std::runtime_error("Cannot seek checkpoint");}
    long n=std::ftell(f);if(n<0 || n>4000000){std::fclose(f);throw std::runtime_error("Invalid checkpoint length");}
    std::rewind(f);std::vector<unsigned char>b(static_cast<size_t>(n));size_t got=std::fread(b.data(),1,b.size(),f);int err=std::ferror(f);std::fclose(f);
    require(!err && got==b.size(),"Checkpoint read failed");return decode(b);
}
inline void save(const std::string& path,const State& s) {
    auto b=encode(s);
    // Exclusive create: existing checkpoint is never replaced, including races.
    #ifdef _WIN32
    int fd=_open(path.c_str(),_O_CREAT|_O_EXCL|_O_WRONLY|_O_BINARY,_S_IREAD|_S_IWRITE);
    require(fd>=0,"Checkpoint exists or cannot be created");
    FILE* f=_fdopen(fd,"wb");if(!f)_close(fd);
#else
    int fd=::open(path.c_str(),O_CREAT|O_EXCL|O_WRONLY,0644);
    require(fd>=0,"Checkpoint exists or cannot be created");
    FILE* f=fdopen(fd,"wb");if(!f)::close(fd);
#endif
    require(f!=nullptr,"Cannot open checkpoint stream");
    bool ok=std::fwrite(b.data(),1,b.size(),f)==b.size();int result=std::fclose(f);
    require(ok && result==0,"Checkpoint write failed (incomplete file retained for diagnosis)");
}
}
#endif