extends Node

var music_resources = []

func _ready():
	preload_all_music("res://BGM")
	preload_all_music("res://SFX") 

func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://main.tscn")

func preload_all_music(folder_path: String):
	if not DirAccess.dir_exists_absolute(folder_path):
		push_error("디렉토리가 존재하지 않음: " + folder_path)
		return
	
	var dir = DirAccess.open(folder_path)
	if dir == null:
		push_error("디렉토리 열기 실패: " + folder_path)
		return
	
	dir.list_dir_begin()
	while true:
		var file_name = dir.get_next()
		if file_name == "":
			break
		if file_name.begins_with("."):
			continue
		var file_path = folder_path.path_join(file_name)
		if dir.current_is_dir():
			continue  # 필요하면 하위 폴더 재귀 가능
		elif file_name.get_extension().to_lower() in ["ogg", "wav", "mp3"]:
			#print("로드 시도: ", file_path)
			var music = ResourceLoader.load(file_path)
			if music:
				music_resources.append(music)
			else:
				push_error("로드 실패: " + file_path)
	dir.list_dir_end()
