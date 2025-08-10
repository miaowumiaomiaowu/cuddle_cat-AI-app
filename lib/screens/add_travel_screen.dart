import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:amap_flutter_map/amap_flutter_map.dart';
// import 'package:amap_flutter_base/amap_flutter_base.dart';
import '../providers/travel_provider.dart';
import '../models/travel_record_model.dart';
import '../services/location_service.dart';
import '../services/photo_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

/// 添加旅行记录页面
class AddTravelScreen extends StatefulWidget {
  static const routeName = '/add-travel';

  const AddTravelScreen({super.key});

  @override
  State<AddTravelScreen> createState() => _AddTravelScreenState();
}

class _AddTravelScreenState extends State<AddTravelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedMood = 'happy';
  final List<String> _tags = [];
  final _tagController = TextEditingController();
  final List<File> _photos = [];
  bool _isSubmitting = false;
  bool _isLoading = false;
  String? _error;

  // 位置相关
  LatLng? _selectedLocation;
  LocationInfo? _selectedLocationInfo;
  List<LocationSuggestion> _locationSuggestions = [];
  List<String> _selectedTags = [];
  List<String> _selectedPhotos = [];
  bool _isSearchingLocation = false;

  // 服务实例
  final LocationService _locationService = LocationService.instance;
  final PhotoService _photoService = PhotoService();

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    // _mapController = null;
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        // 压缩并保存照片
        final String? compressedPath = await _photoService.compressAndSavePhoto(
          pickedFile.path,
          quality: 80,
          maxWidth: 1920,
          maxHeight: 1080,
        );

        if (compressedPath != null) {
          setState(() {
            _photos.add(File(compressedPath));
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('照片处理失败')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('照片处理失败: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  void _addTag(String tag) {
    if (tag.trim().isNotEmpty && !_tags.contains(tag.trim())) {
      setState(() {
        _tags.add(tag.trim());
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _locateToCurrentPosition() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final LocationInfo? locationInfo =
          await _locationService.getCurrentLocation();

      if (locationInfo != null) {
        setState(() {
          _selectedLocation = locationInfo.coordinates;
          _selectedLocationInfo = locationInfo;
          _locationController.text = locationInfo.name;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已定位到: ${locationInfo.name}')),
          );
        }
      } else {
        setState(() {
          _error = '无法获取当前位置';
        });
      }
    } catch (e) {
      setState(() {
        _error = '定位失败：$e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 搜索位置建议
  Future<void> _searchLocationSuggestions(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _locationSuggestions = [];
      });
      return;
    }

    setState(() {
      _isSearchingLocation = true;
    });

    try {
      final suggestions =
          await _locationService.searchLocationSuggestions(query);
      setState(() {
        _locationSuggestions = suggestions;
      });
    } catch (e) {
      debugPrint('搜索位置建议失败: $e');
    } finally {
      setState(() {
        _isSearchingLocation = false;
      });
    }
  }

  /// 选择位置建议
  void _selectLocationSuggestion(LocationSuggestion suggestion) {
    setState(() {
      _selectedLocation = suggestion.coordinates;
      _locationController.text = suggestion.name;
      _locationSuggestions = [];

      // 创建LocationInfo
      _selectedLocationInfo = LocationInfo(
        address: suggestion.address,
        city: suggestion.name,
        latitude: suggestion.latitude,
        longitude: suggestion.longitude,
      );
    });
  }

  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请在地图上选择一个位置')),
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        final newRecord = TravelRecord(
          title: _titleController.text,
          description: _descriptionController.text,
          location: LocationInfo(
            address: _locationController.text,
            latitude: _selectedLocation!.latitude,
            longitude: _selectedLocation!.longitude,
          ),
          mediaItems: _selectedPhotos.map((photo) => MediaItem(
            path: photo,
            type: 'photo',
          )).toList(),
          mood: _selectedMood,
          tags: _selectedTags,
          companions: [],
        );

        final provider = Provider.of<TravelProvider>(context, listen: false);
        await provider.addRecord(newRecord);

        if (mounted) {
          Navigator.of(context).pop(true); // 返回 true 表示添加成功
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('添加旅行记录失败: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加旅行记录'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 错误信息显示
              if (_error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              // 标题
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '标题',
                  hintText: '输入旅行记录标题',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入标题';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 地图选择
              GestureDetector(
                onTap: () async {
                  // 获取 ScaffoldMessenger 在异步操作之前
                  final messenger = ScaffoldMessenger.of(context);

                  // 模拟地图选点
                  setState(() {
                    _isLoading = true;
                  });

                  await Future.delayed(const Duration(seconds: 1));

                  setState(() {
                    _selectedLocation = const LatLng(39.9054, 116.3976); // 北京位置
                    _isLoading = false;
                  });

                  if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('已选择位置: 北京市 (模拟数据)')),
                    );
                  }
                },
                child: Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          '点击此处模拟选择位置',
                          style:
                              TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        if (_selectedLocation != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            '已选择位置: 北京 (${_selectedLocation!.latitude}, ${_selectedLocation!.longitude})',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[500]),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 位置名称和搜索
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _locationController,
                          decoration: InputDecoration(
                            labelText: '位置名称',
                            hintText: '输入位置名称搜索',
                            border: const OutlineInputBorder(),
                            suffixIcon: _isSearchingLocation
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : null,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '请输入位置名称';
                            }
                            return null;
                          },
                          onChanged: _searchLocationSuggestions,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.my_location),
                        onPressed: _isLoading ? null : _locateToCurrentPosition,
                        tooltip: '定位到当前位置',
                      ),
                    ],
                  ),

                  // 位置建议列表
                  if (_locationSuggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _locationSuggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = _locationSuggestions[index];
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.location_on,
                              color: Colors.grey.shade600,
                              size: 20,
                            ),
                            title: Text(
                              suggestion.name,
                              style: const TextStyle(fontSize: 14),
                            ),
                            subtitle: Text(
                              suggestion.address,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            onTap: () => _selectLocationSuggestion(suggestion),
                          );
                        },
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // 心情选择
              const Text('心情：'),
              Wrap(
                spacing: 8,
                children: [
                  _buildMoodChip('happy', '😄 开心'),
                  _buildMoodChip('relaxed', '😌 放松'),
                  _buildMoodChip('excited', '🤩 兴奋'),
                  _buildMoodChip('romantic', '💑 浪漫'),
                  _buildMoodChip('tired', '😪 疲惫'),
                  _buildMoodChip('bored', '😒 无聊'),
                ],
              ),

              const SizedBox(height: 16),

              // 描述
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '描述',
                  hintText: '描述你的旅行体验...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 16),

              // 标签
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tagController,
                      decoration: const InputDecoration(
                        labelText: '添加标签',
                        hintText: '输入标签后按回车',
                        border: OutlineInputBorder(),
                      ),
                      onFieldSubmitted: (value) {
                        _addTag(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _addTag(_tagController.text),
                    tooltip: '添加标签',
                  ),
                ],
              ),

              if (_tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _tags
                        .map((tag) => Chip(
                              label: Text(tag),
                              onDeleted: () => _removeTag(tag),
                            ))
                        .toList(),
                  ),
                ),

              const SizedBox(height: 16),

              // 照片上传
              Row(
                children: [
                  const Text('照片：'),
                  const Spacer(),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('添加照片'),
                    onPressed: _pickImage,
                  ),
                ],
              ),

              if (_photos.isNotEmpty)
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _photos.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8, top: 8),
                        child: Stack(
                          children: [
                            Image.file(
                              _photos[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: InkWell(
                                onTap: () => _removePhoto(index),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 24),

              // 提交按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator()
                      : const Text('保存旅行记录'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodChip(String value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedMood == value,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedMood = value;
          });
        }
      },
    );
  }
}
