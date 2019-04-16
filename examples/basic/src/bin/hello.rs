extern crate basic;
extern crate realm;

pub fn main() {
    realm::main(":8000", basic::forward::magic)
}
