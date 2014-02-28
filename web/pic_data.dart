library picData;

import 'dart:html';

part 'pic_data_data.dart';

class PicData{
  String id='', quote='', author='', info='', _link='';
  num _posX = 0, _posY = 0, _zoom = 1.0;
  num _minZoom = 0.0, _maxZoom = 1.0;
  int _width = 500, _height=500;
  ImageElement _img;
  Element viewer;
  num _viewFactor = 1.0;
  bool initialized = false;

  PicData(this.viewer, this.id, this.quote, this.author, this.info, [src, this._zoom, this._posX, this._posY, this._width, this._height]){
    link = src;
  }

  set zoom(double z){
    _zoom = z / _viewFactor;
    updateViewer();
  }

  num get zoom => _zoom * _viewFactor;

  set viewFactor(num f){
    _viewFactor = f * _viewFactor;
  }

  set link(String src){
    _link = src;
    if (_link.isNotEmpty){
      _img = new ImageElement(src: _link);
      _img.onLoad.listen(_init, onError: (e){print('$_link FAILED: $e');});
    }
  }

  String get link => _link;
  num get minZoom => (_minZoom - 0.05) * _viewFactor;
  num get maxZoom => (_maxZoom + 0.05) * _viewFactor;
  num get stepZoom => (_maxZoom - _minZoom) / 50 * _viewFactor;
  num get posX => _posX * _viewFactor;
  num get posY => _posY * _viewFactor;

  _init(e){
    if (_img == null) return;
    _width = _img.naturalWidth;
    _height = _img.naturalHeight;
    initialized = true;

    var vSize = viewer.clientWidth >= viewer.clientHeight ? viewer.clientHeight : viewer.clientWidth;
    _viewFactor = 1.0;
    var iSize = _width > _height ? _height : _width;
    if (iSize > vSize){
      _minZoom = _width > _height ? vSize / _height : vSize / _width;
      _maxZoom = 1.2;
    } else {
      _maxZoom = _width > _height ? vSize / _height : vSize / _width;
      _minZoom = iSize / vSize;
    }
    _resize();
  }

  incOffset(num x, num y){
    _posX += (x / _viewFactor).round();
    _posY += (y / _viewFactor).round();
    updateViewer();
  }

  _resize(){
    if (viewer != null && initialized){
      if (_zoom < _minZoom) _zoom = _minZoom;
      if (_zoom > _maxZoom) _zoom = _maxZoom;
      var maxX = (viewer.clientWidth - _width * _zoom).round();
      _posX = _posX < maxX ? maxX : _posX;
      var maxY = (viewer.clientHeight - _height * _zoom).round();
      _posY = _posY < maxY ? maxY : _posY;
      _posX = _posX > 0 ? 0 : _posX;
      _posY = _posY > 0 ? 0 : _posY;
    }
  }

  updateViewer(){
    if(viewer != null && initialized){
      _resize();
      var w = (_width*_zoom * _viewFactor).round();
      var h = (_height*_zoom *_viewFactor).round();
      var x = (_posX * _viewFactor).round();
      var y = (_posY * _viewFactor).round();
      viewer
      ..style.backgroundImage = 'url($_link)'
      ..style.backgroundSize = '${w}px ${h}px'
      ..style.backgroundPosition = '${x}px ${y}px';
     }
  }

  String get asQteHtml => '${quote}<div class="qAuthor"><hr>$author</div><hr><div class="qInfo">$info</div>';
  String get asDartSrc{
    String s = 'new PicData(picBox, ';
    s += '"$id", "';
    s += '${quote.replaceAll('\$','\\\$').replaceAll('\"','\\\"')}", "';
    s += '${author.replaceAll('\$','\\\$').replaceAll('\"','\\\"')}", "';
    s += '${info.replaceAll('\$','\\\$').replaceAll('\"','\\\"')}", "';
    s += '${link.replaceAll('\$','\\\$').replaceAll('\"','\\\"')}", ';
    s += '$_zoom, $_posX, $_posY, $_width, $_height)';
    return s;
  }

  String get asHtml{
  String s = '';
    s += '\n        <div id="$id">';
    s += '\n          <div class="quote">$quote</div>';
    s += '\n          <div class="author">$author</div>';
    s += '\n          <div class="info">$info</div>';
    s += '\n          <div class="picInfo">';
    s += '\n            <div class="link">$link</div>';

    if (_width!= null && _height != null){
      s += '\n            <div class="oWidth">${_width.toStringAsFixed(0)}</div>';
      s += '\n            <div class="oHeight">${_height.toStringAsFixed(0)}</div>';
    }

    s += '\n            <div class="posX">${_posX.toStringAsFixed(0)}</div>';
    s += '\n            <div class="posY">${_posY.toStringAsFixed(0)}</div>';
    s += '\n            <div class="zoom">${_zoom.toStringAsFixed(3)}</div>';
    s += '\n          </div>';
    s += '\n        </div>';
    return s;
  }
  String get pzInfo => '$_posX, $_posY | z: ${_zoom.toStringAsFixed(3)} (f: ${_viewFactor.toStringAsFixed(3)})';
}
