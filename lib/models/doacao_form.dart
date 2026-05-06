import 'package:image_picker/image_picker.dart';

class DoacaoForm {
  List<XFile> fotos        = [];
  String titulo            = '';
  String descricao         = '';
  int?   categoriaId;
  String estadoConservacao = '';
  String localRetirada     = '';
  String tipoLogistica     = '';
}