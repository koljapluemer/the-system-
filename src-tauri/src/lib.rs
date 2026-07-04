use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::fs;
use std::path::PathBuf;
use tauri::AppHandle;
use tauri::Manager;

#[derive(Debug, Serialize, Deserialize)]
struct Settings {
    #[serde(rename = "dataFolder")]
    data_folder: Option<String>,
}

fn settings_path(app: &AppHandle) -> Result<PathBuf, String> {
    let dir = app.path().app_data_dir().map_err(|e| e.to_string())?;
    fs::create_dir_all(&dir).map_err(|e| e.to_string())?;
    Ok(dir.join("settings.json"))
}

// Notes live as flat JSON files directly inside the data folder. Reject any
// filename that could escape it (path separators, "..").
fn safe_note_path(folder: &str, filename: &str) -> Result<PathBuf, String> {
    if filename.contains('/') || filename.contains('\\') || filename.contains("..") {
        return Err(format!("invalid filename: {}", filename));
    }
    Ok(PathBuf::from(folder).join(filename))
}

#[tauri::command]
fn get_data_folder(app: AppHandle) -> Result<Option<String>, String> {
    let path = settings_path(&app)?;
    if !path.exists() {
        return Ok(None);
    }
    let contents = fs::read_to_string(&path).map_err(|e| e.to_string())?;
    let settings: Settings = serde_json::from_str(&contents).map_err(|e| e.to_string())?;
    Ok(settings.data_folder)
}

#[tauri::command]
fn set_data_folder(app: AppHandle, path: String) -> Result<(), String> {
    let settings_file = settings_path(&app)?;
    let settings = Settings {
        data_folder: Some(path),
    };
    let contents = serde_json::to_string_pretty(&settings).map_err(|e| e.to_string())?;
    fs::write(&settings_file, contents).map_err(|e| e.to_string())
}

/// Scans the data folder for scratchpad notes that still need triage, i.e.
/// `primaryType == "scratchpad"` and `triaged != "true"`. Returns filenames only;
/// use `read_json_file` to load the full contents of one.
#[tauri::command]
fn list_scratchpad_untriaged(folder: String) -> Result<Vec<String>, String> {
    let dir = PathBuf::from(&folder);
    if !dir.exists() {
        fs::create_dir_all(&dir).map_err(|e| e.to_string())?;
    }
    let entries = fs::read_dir(&dir).map_err(|e| e.to_string())?;
    let mut matches = Vec::new();
    for entry in entries {
        let entry = entry.map_err(|e| e.to_string())?;
        let path = entry.path();
        if path.extension().and_then(|s| s.to_str()) != Some("json") {
            continue;
        }
        let Some(filename) = path.file_name().and_then(|s| s.to_str()) else {
            continue;
        };
        let Ok(contents) = fs::read_to_string(&path) else {
            continue;
        };
        let Ok(value) = serde_json::from_str::<Value>(&contents) else {
            continue;
        };
        let is_scratchpad = value.get("primaryType").and_then(|v| v.as_str()) == Some("scratchpad");
        if !is_scratchpad {
            continue;
        }
        let already_triaged = value.get("triaged").and_then(|v| v.as_str()) == Some("true");
        if already_triaged {
            continue;
        }
        matches.push(filename.to_string());
    }
    Ok(matches)
}

#[tauri::command]
fn read_json_file(folder: String, filename: String) -> Result<Value, String> {
    let path = safe_note_path(&folder, &filename)?;
    let contents = fs::read_to_string(&path).map_err(|e| e.to_string())?;
    serde_json::from_str(&contents).map_err(|e| e.to_string())
}

#[tauri::command]
fn write_json_file(folder: String, filename: String, content: Value) -> Result<(), String> {
    let path = safe_note_path(&folder, &filename)?;
    let contents = serde_json::to_string_pretty(&content).map_err(|e| e.to_string())?;
    fs::write(&path, contents).map_err(|e| e.to_string())
}

#[tauri::command]
fn delete_json_file(folder: String, filename: String) -> Result<(), String> {
    let path = safe_note_path(&folder, &filename)?;
    if path.exists() {
        fs::remove_file(&path).map_err(|e| e.to_string())?;
    }
    Ok(())
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .setup(|app| {
            if cfg!(debug_assertions) {
                app.handle().plugin(
                    tauri_plugin_log::Builder::default()
                        .level(log::LevelFilter::Info)
                        .build(),
                )?;
            }
            Ok(())
        })
        .plugin(tauri_plugin_dialog::init())
        .invoke_handler(tauri::generate_handler![
            get_data_folder,
            set_data_folder,
            list_scratchpad_untriaged,
            read_json_file,
            write_json_file,
            delete_json_file,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
