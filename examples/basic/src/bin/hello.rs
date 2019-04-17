extern crate basic;
extern crate realm;

pub fn main() {
    realm::serve(":8000", basic::forward::magic)
}
