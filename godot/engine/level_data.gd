class_name LevelData
extends RefCounted
## Bir bulmaca: width×height grid, parçalar ve referans çözüm (pid → origin).

var id := ""
var width := 0
var height := 0
var pieces: Array[PieceData] = []
var solution := {}

func piece(pid: String) -> PieceData:
	for p in pieces:
		if p.id == pid:
			return p
	return null
