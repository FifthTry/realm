#[derive(Serialize)]
pub struct TextWidget {}

impl realm::Widget for TextWidget {
    fn realm_id(&self) -> &'static str {
        "Widgets.BWidgets.TextWidget"
    }
}

impl TextWidget {
    pub fn new(_req: &realm::Request) -> TextWidget {
        TextWidget {

        }
    }
}

