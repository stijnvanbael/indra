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
}

class Tag {
  String id;
  DateTime timestamp;

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
