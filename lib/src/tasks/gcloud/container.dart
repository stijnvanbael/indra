import 'gcloud.dart';

class Container {
  final GCloud _gcloud;

  Container(this._gcloud);

  Images get images => Images(_gcloud);
}

class Images {
  final GCloud _gcloud;

  Images(this._gcloud);

  Future<List<ImageTag>> tags(String image, {int? limit}) async {
    var params = [
      'container',
      'images',
      'list-tags',
      '${_gcloud.hostname}/${_gcloud.project}/$image'
    ];
    if (limit != null) {
      params.add('--limit=$limit');
    }
    return (await _gcloud.run(params, showOutput: false))
        .split('\n')
        .skip(1)
        .map(ImageTag.parse)
        .where((tag) => tag != null)
        .map((tag) => tag!)
        .toList();
  }

  Future addTag(
    String image, {
    required String existing,
    required String toAdd,
  }) =>
      _gcloud.run([
        'container',
        'images',
        'add-tag',
        '${_gcloud.hostname}/${_gcloud.project}/$image:$existing',
        '${_gcloud.hostname}/${_gcloud.project}/$image:$toAdd',
        '-q',
      ], showOutput: false);

  Future<List<Image>> list() async {
    var params = [
      'container',
      'images',
      'list',
      '--repository=${_gcloud.hostname}/${_gcloud.project}'
    ];
    return (await _gcloud.run(params, showOutput: false))
        .split('\n')
        .skip(1)
        .map(Image.parse)
        .where((image) => image != null)
        .map((image) => image!)
        .toList();
  }
}

class ImageTag {
  final String id;
  final List<String> tags;
  final DateTime timestamp;

  ImageTag(this.id, this.tags, this.timestamp);

  static ImageTag? parse(String tagLine) {
    var parts = tagLine.split(new RegExp(r'\s+'));
    if (parts.length == 3) {
      return ImageTag(parts[0], parts[1].split(','), DateTime.parse(parts[2]));
    } else {
      return null;
    }
  }
}

class Image {
  final String hostname;
  final String project;
  final String name;

  Image(this.hostname, this.project, this.name);

  static Image? parse(String imageLine) {
    var parts = imageLine.split('/');
    if (parts.length == 3) {
      return Image(parts[0], parts[1], parts[2]);
    } else {
      return null;
    }
  }
}
