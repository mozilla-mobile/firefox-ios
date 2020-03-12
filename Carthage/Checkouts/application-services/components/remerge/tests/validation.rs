use serde::{Deserialize, Serialize};
use serde_json::Value as JsonValue;

const SCHEMAS: &str = include_str!("./test_schemas.json");

#[derive(Serialize, Deserialize, Debug)]
struct SchemaTest {
    #[serde(default)]
    error: Option<String>,
    #[serde(default)]
    remote: bool,
    #[serde(default)]
    skip: bool,
    schema: JsonValue,
}

#[test]
fn test_validation() {
    let schemas: Vec<SchemaTest> = serde_json::from_str(SCHEMAS).unwrap();
    for (i, v) in schemas.into_iter().enumerate() {
        if v.skip {
            eprintln!("Skipping schema number {}", i);
            continue;
        }
        let schema_str = v.schema.to_string();
        let res = remerge::schema::parse_from_string(&schema_str, v.remote);
        if let Some(e) = v.error {
            if let Err(val_err) = res {
                let ve_str = format!("{:?}", val_err);
                if !ve_str.contains(&e) {
                    panic!("Schema number {} should fail to validate with an error like {:?}, but instead failed with {:?}", i, e, ve_str);
                }
            } else {
                panic!(
                    "Schema number {} should fail to validate with error {:?}, but passed",
                    i, e
                );
            }
        } else if let Err(v) = res {
            panic!("Schema number {} should pass, but failed with {:?}", i, v);
        }
    }
}
