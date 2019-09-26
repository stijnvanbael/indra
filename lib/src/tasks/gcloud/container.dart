import 'gcloud.dart';

class Container {
  final GCloud gcloud;

  Container(this.gcloud);

  Images get images => Images(gcloud);
}

class Images {
  final GCloud gcloud;

  Images(this.gcloud);

  Future<List<Tag>> tags(String image, {int limit}) async {
    var params = ['container', 'images', 'list-tags', '${gcloud.hostname}/${gcloud.project}/$image'];
    if (limit != null) {
      params.add('--limit=$limit');
    }
    return (await gcloud.run(params, showOutput: false))
        .split('\n')
        .skip(1)
        .map(Tag.parse)
        .where((tag) => tag != null)
        .toList();
  }

  Future<List<Image>> list() async {
    var params = ['container', 'images', 'list', '--repository=${gcloud.hostname}/${gcloud.project}'];
    return (await gcloud.run(params, showOutput: false))
        .split('\n')
        .skip(1)
        .map(Image.parse)
        .where((image) => image != null)
        .toList();
  }
}

class Tag {
  final String id;
  final DateTime timestamp;

  Tag(this.id, this.timestamp);

  static Tag parse(String tagLine) {
    var parts = tagLine.split(new RegExp(r'\s+'));
    if (parts.length == 3) {
      return Tag(parts[1], DateTime.parse(parts[2]));
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

  static Image parse(String imageLine) {
    var parts = imageLine.split('/');
    if (parts.length == 3) {
      return Image(parts[0], parts[1], parts[2]);
    } else {
      return null;
    }
  }
}
