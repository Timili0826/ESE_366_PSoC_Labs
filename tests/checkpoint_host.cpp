#include "../incremental/checkpoint.hpp"
#include <functional>
#include <iostream>
static void reject(const std::function<void()>& action) {bool caught=false;try{action();}catch(const std::exception&){caught=true;}checkpoint::require(caught,"Invalid checkpoint accepted");}
int main(){try{
    checkpoint::State s;s.initial_ids={0,1,2};s.new_ids={3,4};s.val_ids={5,6};s.order=s.initial_ids;s.dataset_tag=123;s.epoch=2;s.rng=789;s.updates=42;s.cumulative_wall_s=1.5;
    for(size_t l=0;l<3;++l){s.weights.emplace_back(s.widths[l]*s.widths[l+1],0.125f);s.biases.emplace_back(s.widths[l+1],-0.25f);}
    auto bytes=checkpoint::encode(s);auto restored=checkpoint::decode(bytes);
    checkpoint::require(checkpoint::encode(restored)==bytes,"Roundtrip changed state");
    auto corrupt=bytes;corrupt[100]^=1;reject([&]{checkpoint::decode(corrupt);});
    corrupt=bytes;corrupt.pop_back();reject([&]{checkpoint::decode(corrupt);});
    corrupt=bytes;corrupt.push_back(0);reject([&]{checkpoint::decode(corrupt);});
    auto invalid=s;invalid.weights[0][0]=std::numeric_limits<float>::infinity();reject([&]{checkpoint::encode(invalid);});
    invalid=s;invalid.biases[1].pop_back();reject([&]{checkpoint::encode(invalid);});
    invalid=s;invalid.widths[1]=127;reject([&]{checkpoint::encode(invalid);});
    invalid=s;invalid.order={0,0,1};reject([&]{checkpoint::encode(invalid);});
    invalid=s;invalid.new_ids={2,4};reject([&]{checkpoint::encode(invalid);});
    invalid=s;invalid.lr=.02f;reject([&]{checkpoint::encode(invalid);});
    const std::string path="checkpoint_host_test.ckpt";
    checkpoint::save(path,s);reject([&]{checkpoint::save(path,s);});
    checkpoint::require(checkpoint::encode(checkpoint::load(path))==bytes,"Disk roundtrip changed state");
    checkpoint::require(std::remove(path.c_str())==0,"Cannot remove temporary checkpoint");
    std::cout<<"Host checkpoint validation: PASS (serialization/integrity/shape/finiteness/splits/exclusive-create)\n";
    return 0;
}catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}}