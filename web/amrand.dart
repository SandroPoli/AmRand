import 'dart:html';
import 'dart:async';
import 'dart:math' as Math;

const iconsPerSide = 10,
      transitionTime = const Duration(milliseconds: 1000),
      endAnimDone = const Duration(seconds: 3);
num curFace = 0, curIndex = 0, vWidth, vHeight;
num lastFace = -1, lastIndex = -1, showCnt = 0, lastOffsteX, lastOffsteY;
bool mustSave = false, canEdit = true, ready = false, offsetting = false, canOffset = false;
LinkElement dataLink;
InputElement  iSaver;
Element scene, cube, viewBox, picBox, qteBox, picInfo, editor;
List<Element> catBoxes;
List<String> categories = ['der Gesellschaft', 'der Sicherheit', 'der Mode', 'der Legalität', 'des Mögliches', 'des Universum'],
            iDs = ['society', 'security', 'fashion', 'legality', 'other', 'universe'];
Map<String,List<PicData>> quotes;
Element curIcon;
PicData picData;

void main() {
  scene = querySelector('.scene');
  cube = querySelector('.cube');
  viewBox = querySelector('#viewBox');
  picBox = querySelector('#picBox');
  qteBox = querySelector('#quoteBox');
  editor = querySelector('#editor');
  picInfo = querySelector('#picInfo');


  window.onResize.listen(resize);

  querySelector('#btnUpdate').onClick.listen(update);
  querySelector('#btnSearch').onClick.listen(search);
  querySelector('#btnEnter').onClick.listen(enter);
  querySelector('#btnSave').onClick.listen(saveClick);
  querySelector('#iZoom').onChange.listen(updateZoom);
  querySelector('#iLink').onChange.listen(updateLink);
  querySelector('#iOffset').onChange.listen(checkOffset);
  picBox
  ..onMouseDown.listen(startOffset)
  ..onMouseMove.listen(changeOffset)
  ..onMouseUp.listen(endOffset)
  ..onMouseLeave.listen(endOffset);

  scene.onClick.listen(turn);
 // cube.onTransitionEnd.listen((e){showAll(true);});

  dataLink = new LinkElement()
  ..rel = 'import'
  ..href = 'data/data.html'
  ..onLoad.listen(initQuotes);
  document.head.append(dataLink);

}

// --- clicks ----

btnEndClick(e){
  picBox.style.backgroundImage = 'url(img/end.png)';
  picBox.classes.add('tvOff');
  querySelector('#btnEnd').style.display = 'none';
  var t = new Timer(endAnimDone, (){picBox.style.backgroundImage = 'url(img/universe.png)';});
}

enter([e]){
  querySelector('#intro')
      ..classes.add('hidden')
      ..onTransitionEnd.listen((e){e.target.remove();});
}

iconClick(MouseEvent e){
  if (e.toElement == curIcon) return;
  if (curIcon != null){
    showAll(false);
    curIcon..classes.remove('selected');
  }
  curIcon = e.toElement;
  curIcon.classes.add('selected');
  curIndex = int.parse(curIcon.id.replaceAll('icon-',''));
  picData = quotes[iDs[curFace]][curIndex];
  showAll(true);
  print('click on: ${curIcon.id}');
}

checkOffset(e){
  CheckboxInputElement cbx = querySelector('#iOffset');
  canOffset = cbx.checked;
  querySelector('#iZoom').disabled = !canOffset;
  picBox
    ..style.zIndex = canOffset ? '100' : null
    ..style.cursor = canOffset ? 'move' : 'auto'
    ..style.transitionDuration = canOffset ? '0' : null;
  querySelector('#pzInfo').text = canOffset ? picData.pzInfo : 'disabled';
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
  if (picData != null)
    picData
    ..zoom = double.parse(editor.querySelector('#iZoom').value)
    ..updateViewer();
  querySelector('#pzInfo').text = picData.pzInfo;
}

updateLink([e]){
  if (picData != null)
    picData
    ..link = editor.querySelector('#iLink').value
    ..updateViewer();
  querySelector('#pzInfo').text = picData.pzInfo;
}

// --- displayers

showAll(show){
  print('showALL($show) > face:$curFace id: ${iDs[curFace]} ix:$curIndex');
  if (show && curFace == lastFace && curIndex == lastIndex){
    showCnt++;
  } else {
    showCnt = show ? 1 : 0;
  }
  if (show){
    viewBox.classes.remove('hidden');
    querySelectorAll('.amRand').forEach((e){e.classes.remove('hidden');});
    querySelector('#vTitle').text = categories[curFace];
    querySelector('#${iDs[curFace]}').classes.remove('hidden');
    lastFace = curFace;
    lastIndex = curIndex;
  } else {
    viewBox.classes.add('hidden');
    querySelectorAll('.amRand').forEach((e){e.classes.add('hidden');});
    querySelector('#${iDs[curFace]}').classes.add('hidden');
  }

  showPic(show);
  showQte(show);
  showEditor(show);
}

showPic(show){
  print('showPic($show)');
  if (show){
    if (picBox.classes.contains('tvOff')){
       picBox.classes.remove('tvOff');
       querySelector('#btnEnd').style.display = 'block';
    } else {
      if (picData != null){
        picData.updateViewer();
      } else { // set category pic;
        picBox
        ..style.backgroundImage = 'url(img/${iDs[curFace]}.png)'
        ..style.backgroundPosition = '0px 0px'
        ..style.backgroundSize = 'cover';
      }
    }
  } else {
    picBox
    ..style.backgroundImage = 'url(img/${iDs[curFace]}.png)'
    ..style.backgroundPosition = '0px 0px'
    ..style.backgroundSize = 'cover';
  }
}

showQte(show){
  if (show){
    if (picData != null){
      picInfo
      ..innerHtml = picData.info.replaceAll('<br>', '\n')
      ..classes.remove('hidden');

      qteBox
      ..innerHtml = picData.asQteHtml
      ..classes.remove('hidden');
    }
  } else { // hide
    qteBox.classes.add('hidden');
    picInfo.classes.add('hidden');
  }
  print('showQte($show)');
}

showEditor(show){
  if (!canEdit) return;
  if (show){
    if (picData != null){
      editor
      ..querySelector('#tQuote').value = picData.quote.replaceAll('<br>', '\n')
      ..querySelector('#tAuthor').value = picData.author.replaceAll('<br>', '\n')
      ..querySelector('#tInfo').value = picData.info.replaceAll('<br>', '\n')
      ..querySelector('#iLink').value = picData.link
      ..querySelector('#iZoom').min = picData.minZoom.toStringAsFixed(3)
      ..querySelector('#iZoom').max = picData.maxZoom.toStringAsFixed(3)
      ..querySelector('#iZoom').step = picData.stepZoom.toStringAsFixed(3)
      ..querySelector('#iZoom').value = picData.zoom.toStringAsFixed(3)
      ..querySelector('#iZoom').disabled = true
      ..querySelector('#iOffset').disabled = false
      ..querySelector('#iOffset').checked = false
      ..querySelector('#pzInfo').text = picData.pzInfo;
    }
    editor
      ..querySelector('#eId').text = iDs[curFace]
      ..querySelector('#eNum').text = curIndex.toString()
      ..classes.remove('hidden');
  }else{
    editor
    ..querySelector('#tQuote').value = ''
    ..querySelector('#tAuthor').value = ''
    ..querySelector('#tInfo').value = ''
    ..querySelector('#iLink').value = ''
    ..querySelector('#iZoom').min = '0.0'
    ..querySelector('#iZoom').max = '1.2'
    ..querySelector('#iZoom').step = '1.2'
    ..querySelector('#iZoom').value = '1.0'
    ..querySelector('#iZoom').disabled = true
    ..querySelector('#iOffset').disabled = true
    ..classes.add('hidden');
  }
  print('showEditor($show)');
}

// --- initialization

initQuotes(link){
 quotes = new Map<String, List<PicData>>();
 var dataBody = link.target.import;
  iDs.forEach((id){
    var data = dataBody.body.querySelector('#d-$id');
//    if (data != null){
    var entries = new List<PicData>(37);
    for(var i = 1; i <=36; i++){
      var pdId = '${id}$i';
      if (data != null){
        var el = data.querySelector('#$pdId');
        if (el != null){
          var q = el.querySelector('.quote').innerHtml;
          var a = el.querySelector('.author').innerHtml;
          var p = el.querySelector('.info').innerHtml;
          var l = el.querySelector('.link').text;
          var x = num.parse(el.querySelector('.posX').text);
          var y = num.parse(el.querySelector('.posY').text);
          var z = num.parse(el.querySelector('.zoom').text);
          entries[i] = new PicData(picBox, pdId, q, a, p, l, z, x, y);
        }
      }
      quotes[id] = entries;
    }
  });
  init();
}


init(){
  var rnd = new Math.Random();
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
    num iconCnt = 1;
    for(var side = 0; side < 4; side++){
      for(var i = 1; i <= (side.isEven ? iconsPerSide : iconsPerSide-2); i++){
        var iconId = 'iconH'; // e.g. society1
        if ([1,10,19,28].contains(iconCnt)) {
          iconId = 'icon$iconCnt';
        } else {
          iconId = side.isEven ? 'iconH' : 'iconV';
        }
        var imgUrl = 'img/${iconId}.png';
        var icon = new DivElement()
        ..id = 'icon-$iconCnt'
        ..style.zIndex = '$iconCnt'
        ..classes.addAll(['icon', 'side$side', id])
        ..onClick.listen(iconClick)
        ..style.transform = 'rotate(${rnd.nextInt(20)-10}deg)';
        catBox.append(icon);
        ImageElement image = new ImageElement(src: imgUrl);
        image.onLoad.listen((e){icon.style.backgroundImage = 'url($imgUrl)';}, onError: (e){icon.style.backgroundImage = 'url(img/icon.png)';});
        print('init[$side] $iconId');
        iconCnt++;
      }
    }
    if (id == 'universe'){
      var btnEnd = new DivElement()
            ..id = 'btnEnd'
            ..text = 'explore the edge of the universe'
            ..classes.add('btn')
            ..onClick.listen(btnEndClick);
      catBox.append(btnEnd);
    }
  });
  resize();
}

// --- resizing

resize([e]){
  vWidth = window.innerWidth - 220;
  vHeight = window.innerHeight - 100;
  if (vHeight > vWidth)
    vHeight = vWidth;
  else
    vWidth = vHeight;

  viewBox
      ..style.width = '${vWidth}px'
      ..style.height= '${vHeight}px';

   catBoxes.forEach((box){
     var icons = box.querySelectorAll('.icon');
     num iSize = vWidth /10,
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
  showAll(true);
}

turn([e]){
  showAll(false);
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
  showAll(true);
}

update([e]){
  mustSave = true;
  var id = '${iDs[curFace]}${curIndex}';
  var picData = quotes[iDs[curFace]][curIndex];
  var quote = editor.querySelector('#tQuote').value.replaceAll('\n','<br>');
  var author = editor.querySelector('#tAuthor').value.replaceAll('\n','<br>');
  var info = editor.querySelector('#tInfo').value.replaceAll('\n','<br>');
  var link = editor.querySelector('#iLink').value;
  var zoom = num.parse(editor.querySelector('#iZoom').value);
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
  showQte(true);
}

String getDataFileContent(){
  var ts = new DateTime.now().toLocal();
  String content = '<!DOCTYPE html>\n<html>\n  <head>\n   <meta charset="utf-8">\n   <title>data of $ts</title>\n </head>\n <body>';
  quotes.forEach((key, list){
    content += '\n      <div id="d-$key">';
    if (list != null){
      list.forEach((pd){
        if (pd != null)
          content += pd.asHtml;
      });
    }
    content += '\n      </div>';
  });
  content += '\n </body>\n </html>';
  return content;
}

hideOutput(e){
  querySelector('#dataHint').classes.add('hidden');
}

saveClick(e){
  Blob blob = new Blob([getDataFileContent()],'text/plain');

  AnchorElement downloadLink = new AnchorElement(href: Url.createObjectUrlFromBlob(blob))
                 ..text = 'Download me'
                 ..download = 'data(${new DateTime.now().toLocal()}).html';

  downloadLink.onClick.listen((e)=>downloadLink.remove());
  document.body.append(downloadLink);
  downloadLink.click();
}

class PicData{
  String id, quote, author, info, _link='';
  num posX = 0, posY = 0, _zoom = 1.0;
  num _minZoom = 0.0, _maxZoom = 1.0;
  int _width = 500, _height=500;
  ImageElement _img;
  Element viewer;

  PicData(this.viewer, this.id, this.quote, this.author, this.info, [src, this._zoom, this. posX, this.posY]){
    link = src;
  }

  set zoom(double z){
    _zoom = z;
    _resize();
  }

  num get zoom => _zoom;

  set link(String src){
    _link = src;
    if (_link.isNotEmpty){
      _img = new ImageElement(src: _link);
      _img.onLoad.listen(_init);
    }
  }

  String get link => _link;
  String get pzInfo => '$posX, $posY - zoom: ${zoom.toStringAsFixed(3)}';
   num get minZoom => _minZoom - 0.05;
  num get maxZoom => _maxZoom + 0.05;
  num get stepZoom => (_maxZoom - _minZoom) / 50;

  _init(e){
    _width = _img.naturalWidth;
    _height = _img.naturalHeight;
    _img = null;

    var vSize = viewer.clientWidth >= viewer.clientHeight ? viewer.clientHeight : viewer.clientWidth;
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
    posX += x.round();
    posY += y.round();
    updateViewer();
  }

  _resize(){
    if (viewer != null){
      if (zoom < _minZoom) zoom = _minZoom;
      if (zoom > _maxZoom) zoom = _maxZoom;
      var maxX = (viewer.clientWidth - _width * zoom).round();
      posX = posX < maxX ? maxX : posX;
      var maxY = (viewer.clientHeight - _height * zoom).round();
      posY = posY < maxY ? maxY : posY;
      posX = posX > 0 ? 0 : posX;
      posY = posY > 0 ? 0 : posY;
    }
  }

  updateViewer(){
    if(viewer != null){
      _resize();
      var w = (_width*zoom).round();
      var h = (_height*zoom).round();
      viewer
      ..style.backgroundImage = 'url($_link)'
      ..style.backgroundSize = '${(_width*_zoom).round()}px ${(_height*_zoom).round()}px'
      ..style.backgroundPosition = '${posX}px ${posY}px';
     }
  }

  String get asQteHtml => '${quote}<div class="qAuthor"><hr>$author</div>';
  String get asHtml => '\n        <div id="$id">\n          <div class="quote">$quote</div>\n          <div class="author">$author</div>\n          <div class="info">$info</div>\n          <div class="picInfo"><div class="link">$link</div>\n           <div class="posX">${posX.toStringAsFixed(0)}</div>\n           <div class="posY">${posY.toStringAsFixed(0)}</div>\n           <div class="zoom">${zoom.toStringAsFixed(3)}</div>\n        </div>\n        </div>';
}

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

  var qUrl = 'https://www.google.ch/search?q=zitat+über+$whatQte';
  window.open(qUrl, 'quotes');

  var iUrl = 'https://www.google.ch/search?q=$whatPic&source=lnms&tbm=isch&sa=X&ei=E24GU7XYK_Lo7Aah0YDQDQ&sqi=2&ved=0CAcQ_AUoAQ&biw=1920&bih=955';
  window.open(iUrl, 'images');
}