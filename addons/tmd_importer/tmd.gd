class_name TMD
extends Resource

const SIZE: int = 12
const MAGIC: int = 0x41

var data: PackedByteArray
var objects_count: int
var objects: Array[TMDObject] = []

static func create_from_bytes(bytes: PackedByteArray) -> TMD:
	var tmd := TMD.new()
	tmd.data = bytes
	assert(tmd.data.size() >= SIZE, "Not enough bytes to construct TMD header.")
	assert(tmd.data.decode_u32(0) == MAGIC, "Not a valid TMD file.")
	assert(tmd.data.decode_u32(4) == 0, "TMD file does not contain relative addresses.")
	tmd.objects_count = tmd.data.decode_u32(8)
	assert(tmd.objects_count > 0, "TMD file does not contain any objects.")
	tmd.parse_objects()
	return tmd


func parse_objects() -> void:
	var start: int = SIZE # Skip TMD header
	for i in objects_count:
		var object_header_bytes := data.slice(start, start + TMDObject.SIZE)
		var object := TMDObject.create_from_bytes(object_header_bytes)
		object.vertices = object.parse_vertices_from_data(data)
		object.normals = object.parse_normals_from_data(data)
		objects.append(object)
		start = start + TMDObject.SIZE


func to_array_mesh() -> ArrayMesh:
	# TODO: Add support for normals, UVs, etc.
	# TODO: Use indexed vertices, normals, etc.
	var array_mesh := ArrayMesh.new()
	for i in objects.size():
		var indexes: Array[int] = []
		var object: TMDObject = objects[i]
		var start: int = SIZE + object.primitives_start
		for j in object.primitives_count:
			var primitive := TMDPrimitive.create_from_bytes(data.slice(start))
			# TODO: Parse other primitive modes
			match primitive.mode:
				0x30:
					if primitive.flag == 0:
						assert(primitive.olen == 6)
						assert(primitive.ilen == 4)
						var r = primitive.data.decode_u8(0)
						var g = primitive.data.decode_u8(1)
						var b = primitive.data.decode_u8(2)
						var normal_1 := primitive.data.decode_u16(4)
						var point_1 := primitive.data.decode_u16(6)
						var normal_2 := primitive.data.decode_u16(8)
						var point_2 := primitive.data.decode_u16(10)
						var normal_3 := primitive.data.decode_u16(12)
						var point_3 := primitive.data.decode_u16(14)
						indexes.append_array([point_1, point_2, point_3])
					else:
						push_warning("Unhandled primitive with mode 0x%x and flag 0x%x" % [primitive.mode, primitive.flag])
				0x34:
					assert(primitive.olen == 9)
					assert(primitive.ilen == 6)
					var u0 := primitive.data.decode_u8(0)
					var v0 := primitive.data.decode_u8(1)
					var cba := primitive.data.decode_u16(2)
					var u1 := primitive.data.decode_u8(4)
					var v1 := primitive.data.decode_u8(5)
					var tsb := primitive.data.decode_u16(6)
					var u2 := primitive.data.decode_u8(8)
					var v2 := primitive.data.decode_u8(9)
					var normal_1 := primitive.data.decode_u16(12)
					var point_1 := primitive.data.decode_u16(14)
					var normal_2 := primitive.data.decode_u16(16)
					var point_2 := primitive.data.decode_u16(18)
					var normal_3 := primitive.data.decode_u16(20)
					var point_3 := primitive.data.decode_u16(22)
					indexes.append_array([point_1, point_2, point_3])
				0x35, 0x37:
					assert(primitive.olen == 9)
					assert(primitive.ilen == 8)
					var u0 := primitive.data.decode_u8(0)
					var v0 := primitive.data.decode_u8(1)
					var cba := primitive.data.decode_u16(2)
					var u1 := primitive.data.decode_u8(4)
					var v1 := primitive.data.decode_u8(5)
					var tsb := primitive.data.decode_u16(6)
					var u2 := primitive.data.decode_u8(8)
					var v2 := primitive.data.decode_u8(9)
					var r0 := primitive.data.decode_u8(12)
					var g0 := primitive.data.decode_u8(13)
					var b0 := primitive.data.decode_u8(14)
					var r1 := primitive.data.decode_u8(16)
					var g1 := primitive.data.decode_u8(17)
					var b1 := primitive.data.decode_u8(18)
					var r2 := primitive.data.decode_u8(20)
					var g2 := primitive.data.decode_u8(21)
					var b2 := primitive.data.decode_u8(22)
					var point_1 := primitive.data.decode_u16(24)
					var point_2 := primitive.data.decode_u16(26)
					var point_3 := primitive.data.decode_u16(28)
					indexes.append_array([point_1, point_2, point_3])
				_:
					push_warning("Unhandled primitive mode: 0x%x" % primitive.mode)
			start = start + 4 + primitive.data.size()
		if indexes.size() > 0:
			var surface_arrays = []
			surface_arrays.resize(Mesh.ARRAY_MAX)
			surface_arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(object.vertices)
			surface_arrays[Mesh.ARRAY_INDEX] = PackedInt32Array(indexes)
			array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_arrays)
	if array_mesh.get_surface_count() == 0:
		push_warning("Array mesh has 0 surfaces.")
	return array_mesh


class TMDObject:
	const SIZE: int = 28

	var vertices_start: int
	var vertices_count: int
	var normals_start: int
	var normals_count: int
	var primitives_start: int
	var primitives_count: int

	var vertices: Array[Vector3i] = []
	var normals: Array[Vector3i] = []

	static func create_from_bytes(bytes: PackedByteArray) -> TMDObject:
		assert(bytes.size() >= SIZE, "Not enough bytes to create TMD object header.")
		var object := TMDObject.new()
		object.vertices_start = bytes.decode_u32(0)
		object.vertices_count = bytes.decode_u32(4)
		object.normals_start = bytes.decode_u32(8)
		object.normals_count = bytes.decode_u32(12)
		object.primitives_start = bytes.decode_u32(16)
		object.primitives_count = bytes.decode_u32(20)
		return object


	func parse_vertices_from_data(data: PackedByteArray) -> Array[Vector3i]:
		return parse_vectors_from_data(data, vertices_start + 12, vertices_count)


	func parse_normals_from_data(data: PackedByteArray) -> Array[Vector3i]:
		return parse_vectors_from_data(data, normals_start + 12, normals_count)


	func parse_vectors_from_data(data: PackedByteArray, start: int, count: int) -> Array[Vector3i]:
		var vectors: Array[Vector3i] = []
		var size: int = 8
		for i in count:
			var vector_data := data.slice(start, start + size)
			var x: int = vector_data.decode_s16(0)
			var y: int = vector_data.decode_s16(2)
			var z: int = vector_data.decode_s16(4)
			vectors.append(Vector3i(x, y, z))
			start = start + size
		return vectors


class TMDPrimitive:
	var olen: int
	var ilen: int
	var flag: int
	var mode: int
	var data: PackedByteArray

	static func create_from_bytes(bytes: PackedByteArray) -> TMDPrimitive:
		var primitive := TMDPrimitive.new()
		primitive.olen = bytes.decode_u8(0)
		primitive.ilen = bytes.decode_u8(1)
		primitive.flag = bytes.decode_u8(2)
		primitive.mode = bytes.decode_u8(3)
		primitive.data = bytes.slice(4, 4 + (primitive.ilen * 4))
		return primitive
