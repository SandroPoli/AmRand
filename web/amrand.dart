import 'dart:html';
import 'dart:math' as Math;
import 'pic_data.dart';

// --- constants
const iconsPerSide = 8;

// --- globals
num
  curFace = 0,
  curIndex = 0,
  vWidth,
  vHeight,
  lastFace = -1,
  lastIndex = -1,
  showCnt = 0,
  lastOffsteX,
  lastOffsteY;

// -- flags
bool
  mustSave = false,
  canEdit = false,
  ready = false,
  offsetting = false,
  canOffset = false,
  dbg = true;

// -- elements
InputElement
  iSaver,
  iLink,
  iZoom,
  iOffset;
TextAreaElement
  tQuote,
  tAuthor,
  tInfo,
  tIntro;
Element
  curIcon,
  pzInfo,
  scene,
  cube,
  viewBox,
  qteBox,
  editor,
  eIntro;

LinkElement dataLink;
List<Element> catBoxes;

// -- cube faces
List<String> categories = ['der Gesellschaft', 'der Sicherheit', 'der Trends', 'der Legalität', 'heute', 'des Universum'];
List<String>        iDs = ['society', 'security', 'fashion', 'legality', 'other', 'universe'];

PicData picData;

// -- random util
Math.Random rnd = new Math.Random();

// --- main (web) app
void main() {

  dbgOut('main: started...');
  querySelector('#introText').innerHtml = introText;

  // --- init global elements
  scene = querySelector('.scene');
  cube = querySelector('.cube');
  viewBox = querySelector('#viewBox');
  picBox = querySelector('#picBox');
  qteBox = querySelector('#quoteBox');
  editor = querySelector('#editor');
  tQuote = editor.querySelector('#tQuote');
  tAuthor = editor.querySelector('#tAuthor');
  tInfo = editor.querySelector('#tInfo');
  iLink = editor.querySelector('#iLink');
  iZoom = editor.querySelector('#iZoom');
  iOffset = editor.querySelector('#iOffset');
  pzInfo = editor.querySelector('#pzInfo');
  eIntro = querySelector('#eIntro');
  tIntro = querySelector('#tIntro');

  dbgOut('main: globals initialized...');

  dbgOut('main: data loading started...');

  // --- intro events
  querySelector('#btnUpdate').onClick.listen(update);
  querySelector('#btnSearch').onClick.listen(search);
  querySelector('#btnSave').onClick.listen(saveClick);
  querySelector('#btnEnter').onClick.listen(enter);
  querySelector('#btnSaveIntro').onClick.listen(saveIntro);
  querySelector('.intro').onClick.listen(smallIntroClick);
  querySelector('.edit').onClick.listen(smallEditClick);

  dbgOut('main: intro events set...');

  // --- editor events
  iZoom.onChange.listen(updateZoom);
  iLink.onChange.listen(updateLink);
  iOffset.onChange.listen(checkOffset);
  picBox
  ..onMouseDown.listen(startOffset)
  ..onMouseMove.listen(changeOffset)
  ..onMouseUp.listen(endOffset)
  ..onMouseLeave.listen(endOffset);

  dbgOut('main: editor events set...');

  // --- cube events
  scene.onClick.listen(turn);
  cube.onTransitionEnd.listen(turned);

  dbgOut('main: cube events set...');

  // --- window evenets
  window.onResize.listen(resize);

  dbgOut('main: window events set...');

  initQuotes(null);
}

dbgOut(txt) => dbg ?  print(txt) : {};

// --- click events ----

enter([e]){
  dbgOut('enterBtn clicked...');
  querySelector('#intro').classes.add('hidden');
  if (!canEdit) eIntro.classes.add('hidden');
}

saveIntro(e){
  introText = tIntro.value.replaceAll('\n', '<br>');
  querySelector('#introText').innerHtml = introText;
}

smallIntroClick(e){
  dbgOut('introBtn clicked...');
  querySelector('#intro').classes.remove('hidden');
  if (canEdit){
    tIntro.value = introText.replaceAll('<br>', '\n');
    tIntro.style.height = '${querySelector("#introText").clientHeight}px';
    eIntro.classes.remove('hidden');
  } else {
    eIntro.classes.add('hidden');
  }
}

smallEditClick(e){
  dbgOut('editBtn clicked...');
  hideAll();
  canEdit = !canEdit;
  showAll();
}

showDetails(show){
  dbgOut('show details($show)');
  showPic(show);
  showQte(show);
  showEditor(show);
}

iconClick(MouseEvent e){
  Element el = e.toElement;
  if (el == curIcon && el.classes.contains('selected')) return;
  if (curIcon != null) {
    curIcon..classes.remove('selected');
    showDetails(false);
  }
  curIcon = e.toElement;
  curIcon.classes.add('selected');
  curIndex = int.parse(curIcon.id.replaceAll('icon-${iDs[curFace]}-',''));
  if (iDs[curFace] == 'universe'){
    querySelector('#tv').classes.add('tvOff');
    picData = quotes[iDs[curFace]][0];
  } else {
    picData = quotes[iDs[curFace]][curIndex];
    dbgIcon(iDs[curFace], curIndex);
  }
  dbgOut('iconClick on: ${curIcon.id}');
}

iconDone(e){
  showDetails(true);
}

checkOffset(e){
  CheckboxInputElement cbx = querySelector('#iOffset');
  canOffset = cbx.checked;
  iZoom.disabled = !canOffset;
  picBox
    ..style.zIndex = canOffset ? '100' : null
    ..style.cursor = canOffset ? 'move' : 'auto'
    ..style.transitionDuration = canOffset ? '0' : null;
  querySelector('#pzInfo').text = (canOffset && picData != null) ? picData.pzInfo : 'disabled';
}

startOffset(MouseEvent e){
  if (!canOffset) return;
  if(!offsetting && picData != null){
    offsetting = true;
    lastOffsteX = e.offset.x;
    lastOffsteY = e.offset.y;
    querySelector('#pzInfo').text = picData.pzInfo;
  }
}

changeOffset(MouseEvent e){
  if (!canOffset) return;
  if (offsetting){
    picData.incOffset(e.offset.x-lastOffsteX, e.offset.y-lastOffsteY);
    lastOffsteX = e.offset.x;
    lastOffsteY = e.offset.y;
    querySelector('#pzInfo').text = picData.pzInfo;
  }
}

endOffset(e){
  if (!canOffset) return;
  if (offsetting){
    offsetting = false;
    querySelector('#pzInfo').text = picData.pzInfo;
  }
}

updateZoom([e]){
  if (picData != null){
    picData
    ..zoom = double.parse(iZoom.value)
    ..updateViewer();
    querySelector('#pzInfo').text = picData.pzInfo;
  }
}

updateLink([e]){
  if (picData != null){
    picData
    ..link = iLink.value
    ..updateViewer();
    querySelector('#pzInfo').text = picData == null ? '' : picData.pzInfo;
  }
}

// --- displayers

hideAll(){
  dbgOut('hideALL()');
  showViewBox(false);
  showDetails(false);
}

showAll(){
  dbgOut('showALL()');
  showViewBox(true);
  showDetails(true);
}

showViewBox(show){
  dbgOut('showViewBox($show)');
  if (show){
    viewBox.classes.remove('hidden');
    picBox
         ..style.backgroundImage = 'url(img/${iDs[curFace]}.png)'
         ..style.backgroundPosition = '0px 0px'
         ..style.backgroundSize = 'cover';
    querySelectorAll('.amRand').forEach((e){e.classes.remove('hidden');});
    querySelector('#vTitle').text = categories[curFace];
    querySelector('#${iDs[curFace]}').classes.remove('hidden');
    lastFace = curFace;
    lastIndex = curIndex;
  } else {
    viewBox.classes.add('hidden');
    querySelectorAll('.amRand').forEach((e){e.classes.add('hidden');});
    querySelector('#${iDs[curFace]}').classes.add('hidden');
    querySelector('#tv').classes.remove('tvOff');
    if (curIcon != null)curIcon.classes.remove('selected');
  }
}

showPic(show){
  dbgOut('showPic($show)');
  if (show){
    if (picData != null){
      picData.updateViewer();
//    } else if (iDs[curFace] == 'universe'){ // set category pic;
//      picBox.style.backgroundImage = null;
    } else { // set category pic;
      picBox
      ..style.backgroundImage = 'url(img/${iDs[curFace]}.png)'
      ..style.backgroundPosition = '0px 0px'
      ..style.backgroundSize = 'cover';
    }
  } else {
    picBox
      ..style.backgroundImage = 'url(img/${iDs[curFace]}.png)'
      ..style.backgroundPosition = '0px 0px'
      ..style.backgroundSize = 'cover';
  }
}

showQte(show){
  dbgOut('showQte($show)');
  if (show){
    if (picData != null){
      qteBox
      ..innerHtml = picData.asQteHtml
      ..classes.remove('hidden');
    }
  } else { // hide
    qteBox
    ..innerHtml = (picData != null ? picData.asQteHtml : (canEdit ? 'quote missing!' : ''))
    ..classes.add('hidden');
  }
}

showEditor(show){
  dbgOut('showEditor($show)');
  if (!canEdit) return;
  if (show){
    if (picData != null){
      tQuote.value = picData.quote.replaceAll('<br>', '\n');
      tAuthor.value = picData.author.replaceAll('<br>', '\n');
      tInfo.value = picData.info.replaceAll('<br>', '\n');
      iLink.value = picData.link;
      iZoom
      ..min = picData.minZoom.toStringAsFixed(3)
      ..max = picData.maxZoom.toStringAsFixed(3)
      ..step = picData.stepZoom.toStringAsFixed(3)
      ..value = picData.zoom.toStringAsFixed(3)
      ..disabled = true;
      iOffset
      ..disabled = false
      ..checked = false;
      pzInfo.text = picData.pzInfo;
    }
    editor
      ..querySelector('#eId').text = iDs[curFace]
      ..querySelector('#eNum').text = curIndex.toString()
      ..classes.remove('hidden');
  }else{
    tQuote.value = '';
    tAuthor.value = '';
    tInfo.value = '';
    iLink.value = '';
    iZoom
    ..min = '0.0'
    ..max = '1.2'
    ..step = '1.2'
    ..value = '1.0'
    ..disabled = true;
    iOffset.disabled = true;
    editor.classes.add('hidden');
    tIntro.classes.add('hidden');
  }
}

// --- initialization

initQuotes(e){
  dbgOut('initQuote()');
  init();
}


init(){
  dbgOut('init()');
  for(var i = 0; i < cube.children.length; i++){
    var face = cube.children[i];
    face
    ..innerHtml = '<br>${categories[i].replaceAll(' ', '<br>')}'
    ..style.backgroundImage = 'url(img/${iDs[i]}.png)';
  }
  catBoxes = new List<Element>();
  iDs.forEach((id){
    var catBox = new DivElement()
    ..id = id
    ..classes.addAll(['catBox', 'hidden']);
    viewBox.append(catBox);
    catBoxes.add(catBox);
    num iconCnt = 0;
    for(var side = 0; side < 4; side++){
      for(var i = 1; i <= (side.isEven ? iconsPerSide : iconsPerSide-2); i++){
        var iconId = 'iconH'; // e.g. society1
        var icon = new DivElement()
        ..id = 'icon-$id-$iconCnt'
        ..title = 'click zum Zeigen'
        ..style.zIndex = '$iconCnt'
        ..classes.addAll(['icon', 'side$side', id])
        ..onTransitionEnd.listen(iconDone)
        ..onClick.listen(iconClick);
        catBox.append(icon);
        dbgIcon(id, i, icon);
        iconCnt++;
      }
    }
    if (id == 'universe'){
      var tv = new DivElement()
      ..id = 'tv'
      ..text = 'nichts (?)'
      ..classes.add('tv');
      catBox.append(tv);
    }
  });
  ready = true;
  querySelector('#btnEnter').classes.remove('hidden');
  querySelector('#loading').classes.add('hidden');
  dbgOut('init() done = ready');
  resize();
}

dbgIcon(id, i,[icon]){
  if (icon == null) icon = querySelector('#icon-$id-$i');
  if (icon == null) return;;
  if (canEdit){
    var pd = quotes[id][i];
    if (pd == null){
      icon
      ..text = 'EMPTY'
      ..classes.add('empty');
    } else if (pd.link.isEmpty) {
      icon
      ..text = 'NO image'
      ..classes.add('noPic');
    } else if (pd.quote.isEmpty) {
      icon
      ..text = 'NO quote'
      ..classes.add('noQte');
    } else if (pd.author.isEmpty) {
      icon
      ..text = 'NO author'
      ..classes.add('noAuthor');
    } else if (pd.info.isEmpty) {
      icon
      ..text = 'NO info'
      ..classes.add('noInfo');
    } else {
      icon
      ..text = 'ok'
      ..classes.remove('empty')
      ..classes.remove('noQte')
      ..classes.remove('noAuthor')
      ..classes.remove('noInfo');
    }
  }
  icon.style.transform = 'rotate(${rnd.nextInt(20)-10}deg)';
}
// --- resizing

resize([e]){
  if (!ready) return;
  hideAll();
  var oldSize = vWidth;
  vWidth = 600; // window.innerWidth - 220;
  vHeight = 600; // window.innerHeight - 100;
  if (vHeight > vWidth)
    vHeight = vWidth;
  else
    vWidth = vHeight;

  viewBox
      ..style.width = '${vWidth}px'
      ..style.height= '${vHeight}px';

  catBoxes.forEach((box){
    var icons = box.querySelectorAll('.icon');
    num iSize = vWidth /iconsPerSide,
        side0cnt=0,
        side1cnt=1,
        side2cnt=0,
        side3cnt=1;
    icons.forEach((Element icon){
      icon
      ..style.width = '${iSize}px'
      ..style.height = '${iSize}px';
      if(icon.classes.contains('side0')){
        icon
        ..style.top= '0px'
        ..style.left = '${side0cnt*iSize}px';
        side0cnt++;
      } else if(icon.classes.contains('side1')){
        icon
        ..style.top = '${side1cnt*iSize}px'
        ..style.right = '0px';
        side1cnt++;
      } else if(icon.classes.contains('side2')){
        icon
        ..style.bottom = '0px'
        ..style.right = '${side2cnt*iSize}px';
        side2cnt++;
      } else if(icon.classes.contains('side3')){
        icon
        ..style.left= '0px'
        ..style.bottom = '${side3cnt*iSize}px';
        side3cnt++;
      }
    });
  });
  if (oldSize != vWidth && oldSize != null){
    quotes.forEach((k, v){
      v.forEach((pd){
        if (pd != null)
          pd.viewFactor = vWidth / oldSize;
      });
    });
  }
  showAll();
}

turn([e]){
  hideAll();
  qteBox.classes.remove('side$curFace');
  picData = null;
  showCnt = 0;
  curIndex = 0;
  curFace = curFace == 5 ? 0 : curFace + 1;
  switch(curFace){
    case 0: cube.style.transform = null; break;
    case 5: cube.style.transform = 'rotateX(80deg) rotateY(5deg)';break;
    case 2: cube.style.transform = 'rotateY(100deg) rotateX(-5deg)';break;
    case 3: cube.style.transform = 'rotateY(-80deg) rotateX(-5deg)';break;
    case 4: cube.style.transform = 'rotateX(-85deg) rotateY(5deg)';break;
    case 1: cube.style.transform = 'rotateY(170deg) rotateX(-5deg)';break;
  }
}

turned([e]){
  showViewBox(true);
  qteBox.classes.add('side$curFace');
}

update([e]){
  mustSave = true;
  var id = '${iDs[curFace]}${curIndex}';
  var picData = quotes[iDs[curFace]][curIndex];
  var quote = tQuote.value.replaceAll('\n','<br>');
  var author = tAuthor.value.replaceAll('\n','<br>');
  var info = tInfo.value.replaceAll('\n','<br>');
  var link = iLink.value;
  var zoom = double.parse(iZoom.value);
  if (picData != null){
    picData
    ..quote = quote
    ..author = author
    ..info = info
    ..link = link
    ..zoom = zoom
    ..updateViewer();
  } else {
    picData = quotes[iDs[curFace]][curIndex] = new PicData(picBox, id, quote, author, info, link, zoom, 0, 0);
  }
  dbgIcon(iDs[curFace], curIndex);
  showQte(true);
}

String getDataFileContent(){
  var content = '/* ==== generated data file ==== */';
  content += '\n\npart of picData;';
  content += '\n\nElement picBox;';
  content += '\n\nString introText = "$introText";';
  content += '\n\nMap<String, List<PicData>> quotes = {';
  quotes.forEach((key, list){
    var lStr = '';
    if (list != null){
      content += '\n               "$key" : [';
      list.forEach((pd){
        if (pd != null){
          pd.id = '$key${list.indexOf(pd)}';
          lStr += '\n                         ${pd.asDartSrc},';
        }
      });
      for(var i=list.length;i<28;i++){
        lStr+='null,';
      }
      if (lStr[lStr.length-1] == ',')
          lStr = lStr.substring(0, lStr.length-1);
      content += '$lStr';
      content +='\n                         ],';
    }
  });
  if (content[content.length-1] == ',')
    content = content.substring(0, content.length-1);
  content += '\n };';
  return content;
}

//String getDataFileContent(){
//  var ts = new DateTime.now().toLocal();
//  String content = '<!DOCTYPE html>\n<html>\n  <head>\n   <meta charset="utf-8">\n   <title>data of $ts</title>\n </head>\n <body>';
//  quotes.forEach((key, list){
//    content += '\n      <div id="d-$key">';
//    if (list != null){
//      list.forEach((pd){
//        if (pd != null)
//          content += pd.asHtml;
//      });
//    }
//    content += '\n      </div>';
//  });
//  content += '\n </body>\n </html>';
//  return content;
//}

hideOutput(e){
  querySelector('#dataHint').classes.add('hidden');
}

saveClick(e){
  Blob blob = new Blob([getDataFileContent()],'text/plain');

  AnchorElement downloadLink = new AnchorElement(href: Url.createObjectUrlFromBlob(blob))
                 ..text = 'Download me'
                 ..download = 'pic_data_data.dart';

  downloadLink.onClick.listen((e)=>downloadLink.remove());
  document.body.append(downloadLink);
  downloadLink.click();
}

//class PicData{
//  String id='', quote='', author='', info='', _link='';
//  num _posX = 0, _posY = 0, _zoom = 1.0;
//  num _minZoom = 0.0, _maxZoom = 1.0;
//  int _width = 500, _height=500;
//  ImageElement _img;
//  Element viewer;
//  num _viewFactor = 1.0;
//  bool initialized = false;
//
//  PicData(this.viewer, this.id, this.quote, this.author, this.info, [src, this._zoom, this._posX, this._posY, this._width, this._height]){
//    link = src;
//  }
//
//  set zoom(double z){
//    _zoom = z / _viewFactor;
//    updateViewer();
//  }
//
//  num get zoom => _zoom * _viewFactor;
//
//  set viewFactor(num f){
//    _viewFactor = f * _viewFactor;
//  }
//
//  set link(String src){
//    _link = src;
//    if (_link.isNotEmpty){
//      _img = new ImageElement(src: _link);
//      _img.onLoad.listen(_init, onError: (e){dbgOut('$_link FAILED: $e');});
//    }
//  }
//
//  String get link => _link;
//  num get minZoom => (_minZoom - 0.05) * _viewFactor;
//  num get maxZoom => (_maxZoom + 0.05) * _viewFactor;
//  num get stepZoom => (_maxZoom - _minZoom) / 50 * _viewFactor;
//  num get posX => _posX * _viewFactor;
//  num get posY => _posY * _viewFactor;
//
//  _init(e){
//    if (_img == null) return;
//    _width = _img.naturalWidth;
//    _height = _img.naturalHeight;
//    initialized = true;
//
//    var vSize = viewer.clientWidth >= viewer.clientHeight ? viewer.clientHeight : viewer.clientWidth;
//    _viewFactor = 1.0;
//    var iSize = _width > _height ? _height : _width;
//    if (iSize > vSize){
//      _minZoom = _width > _height ? vSize / _height : vSize / _width;
//      _maxZoom = 1.2;
//    } else {
//      _maxZoom = _width > _height ? vSize / _height : vSize / _width;
//      _minZoom = iSize / vSize;
//    }
//    _resize();
//  }
//
//  incOffset(num x, num y){
//    _posX += (x / _viewFactor).round();
//    _posY += (y / _viewFactor).round();
//    updateViewer();
//  }
//
//  _resize(){
//    if (viewer != null && initialized){
//      if (_zoom < _minZoom) _zoom = _minZoom;
//      if (_zoom > _maxZoom) _zoom = _maxZoom;
//      var maxX = (viewer.clientWidth - _width * _zoom).round();
//      _posX = _posX < maxX ? maxX : _posX;
//      var maxY = (viewer.clientHeight - _height * _zoom).round();
//      _posY = _posY < maxY ? maxY : _posY;
//      _posX = _posX > 0 ? 0 : _posX;
//      _posY = _posY > 0 ? 0 : _posY;
//    }
//  }
//
//  updateViewer(){
//    if(viewer != null && initialized){
//      _resize();
//      var w = (_width*_zoom * _viewFactor).round();
//      var h = (_height*_zoom *_viewFactor).round();
//      var x = (_posX * _viewFactor).round();
//      var y = (_posY * _viewFactor).round();
//      viewer
//      ..style.backgroundImage = 'url($_link)'
//      ..style.backgroundSize = '${w}px ${h}px'
//      ..style.backgroundPosition = '${x}px ${y}px';
//     }
//  }
//
//  String get asQteHtml => '${quote}<div class="qAuthor"><hr>$author</div><hr><div class="qInfo">$info</div>';
//  String get asDartSrc{
//    String s = 'new PicData(picBox, ';
//    s += '"$id", "';
//    s += '${quote.replaceAll('\$','\\\$').replaceAll('\"','\\\"')}", "';
//    s += '${author.replaceAll('\$','\\\$').replaceAll('\"','\\\"')}", "';
//    s += '${info.replaceAll('\$','\\\$').replaceAll('\"','\\\"')}", "';
//    s += '${link.replaceAll('\$','\\\$').replaceAll('\"','\\\"')}", ';
//    s += '$_zoom, $_posX, $_posY, $_width, $_height)';
//    return s;
//  }
//
//  String get asHtml{
//  String s = '';
//    s += '\n        <div id="$id">';
//    s += '\n          <div class="quote">$quote</div>';
//    s += '\n          <div class="author">$author</div>';
//    s += '\n          <div class="info">$info</div>';
//    s += '\n          <div class="picInfo">';
//    s += '\n            <div class="link">$link</div>';
//
//    if (_width!= null && _height != null){
//      s += '\n            <div class="oWidth">${_width.toStringAsFixed(0)}</div>';
//      s += '\n            <div class="oHeight">${_height.toStringAsFixed(0)}</div>';
//    }
//
//    s += '\n            <div class="posX">${_posX.toStringAsFixed(0)}</div>';
//    s += '\n            <div class="posY">${_posY.toStringAsFixed(0)}</div>';
//    s += '\n            <div class="zoom">${_zoom.toStringAsFixed(3)}</div>';
//    s += '\n          </div>';
//    s += '\n        </div>';
//    return s;
//  }
//  String get pzInfo => '$_posX, $_posY | z: ${_zoom.toStringAsFixed(3)} (f: ${_viewFactor.toStringAsFixed(3)})';
//}

search(e){
  update();
  var whatPic = '${iDs[curFace]}';
  var whatQte = '${categories[curFace]}';
  try{
    var picData = quotes[iDs[curFace]][curIndex];
    if (picData.info.isNotEmpty){
      whatPic += '+${picData.info.replaceAll(' ', '+')}';
      whatQte += '+${picData.info.replaceAll(' ', '+')}';
    }
  } catch(e){

  }

  var qUrl = 'https://www.google.ch/search?q=zitat+Ã¼ber+$whatQte';
  window.open(qUrl, 'quotes');

  var iUrl = 'https://www.google.ch/search?q=$whatPic&source=lnms&tbm=isch&sa=X&ei=E24GU7XYK_Lo7Aah0YDQDQ&sqi=2&ved=0CAcQ_AUoAQ&biw=1920&bih=955';
  window.open(iUrl, 'images');
}