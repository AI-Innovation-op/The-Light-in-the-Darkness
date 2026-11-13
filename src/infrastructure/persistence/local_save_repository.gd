extends RefCounted
## Adapter for Godot user storage. Backup keeps the last valid checkpoint.
var path = "user://oakhaven_v1.json"
var message = ""

func write(data: Dictionary) -> bool:
    var file = FileAccess.open(path+".tmp",FileAccess.WRITE)
    if file == null:
        message = "No se pudo guardar. Puedes seguir jugando."
        return false
    file.store_string(JSON.stringify(data))
    file.close()
    if FileAccess.file_exists(path):
        DirAccess.copy_absolute(path,path+".bak")
    var error = DirAccess.rename_absolute(path+".tmp",path)
    message = "Progreso guardado" if error == OK else "No se pudo confirmar el guardado."
    return error == OK

func read() -> Variant:
    for candidate in [path,path+".bak"]:
        if FileAccess.file_exists(candidate):
            var parser = JSON.new()
            if parser.parse(FileAccess.get_file_as_string(candidate)) == OK:
                var data = parser.data
                if data is Dictionary and data.get("version")==1:
                    return data
    return null
