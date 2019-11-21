extern crate proc_macro;
extern crate proc_macro2;
#[macro_use]
extern crate syn;
#[macro_use]
extern crate quote;
use proc_macro::TokenStream;
use syn::{
    parse::{Parse, ParseStream, Result},
    DeriveInput, ItemFn, ItemStruct, LitStr, Token,
};

use std::path::Path;
mod utils;

extern crate inflector;

#[proc_macro_attribute]
pub fn db_test(_metadata: TokenStream, input: TokenStream) -> TokenStream {
    let fn_item: ItemFn = parse_macro_input!(input as ItemFn);
    let fn_ident = fn_item.ident;
    let visibility = fn_item.vis;
    let _inputs = fn_item.decl.inputs;
    let output = fn_item.decl.output;
    let block = fn_item.block;
    (quote! {
        #[test]
        #visibility fn #fn_ident() #output {
            db_test(|conn|{
                #block
            })
        }
    })
    .into()
}

// realm_page macro stuff

#[derive(Debug)]
struct PathArgs {
    id: String,
}

mod keyword {
    syn::custom_keyword!(id);
}

impl Parse for PathArgs {
    fn parse(input: ParseStream) -> Result<Self> {
        input.parse::<keyword::id>()?;
        input.parse::<Token![=]>()?;
        let path: LitStr = input.parse()?;
        Ok(PathArgs { id: path.value() })
    }
}





#[proc_macro_attribute]
pub fn realm_page(meta: TokenStream, input: TokenStream) -> TokenStream {
    let id = parse_macro_input!(meta as PathArgs).id;


    let mut html_path = utils::convert_id_to_html_path(&id);
    // if id = "Pages.Foo.BarBaz", html_path should be "foo/bar-baz.html"
    // lower case, convert dot to slash, convert camel case to kabab case
    let input_clone = input.clone();
    let derive_input = parse_macro_input!(input_clone as DeriveInput);
    let struct_item: ItemStruct = parse_macro_input!(input as ItemStruct);
    let ident = struct_item.ident;

    println!("html path: {:?}", html_path);
    if !Path::new(&html_path).is_file(){
        println!("inside realm_page(): no html file found for this realm page");
        html_path = "empty.html".to_string();
    }
    // if html_path exists, then include Template stuff, else let them be

    let q = quote! {
         #[derive(Serialize)]
         #[derive(Template)]
         #[template(path = html_path.as_str())]
         #derive_input

         impl realm::Page for #ident {
            const ID: &'static str = #id;
        }
    };
    q.into()
}

