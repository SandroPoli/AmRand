import 'dart:html';
import 'dart:async';
import 'dart:math' as Math;

const iconsPerSide = 10,
      transitionTime = const Duration(milliseconds: 1000),
      endAnimDone = const Duration(seconds: 3);
num curFace = 0, curIndex = 0, vWidth, vHeight;
bool mustSave = false, canEdit = true;
LinkElement dataLink;
InputElement  iSaver;
Element scene, cube, viewBox, picBox, qteBox, picInfo, editor, btnUpdate, btnSave;
List<Element> catBoxes;
List<String> categories = ['der Gesellschaft', 'der Sicherheit', 'der Mode', 'der Legalität', 'des Mögliches', 'des Universum'],
            iDs = ['society', 'security', 'fashion', 'legality', 'other', 'universe'];
Map<String,List<PicData>> quotes;
Element curIcon;

void main() {
  dataLink = new LinkElement()
  ..rel = 'import'
  ..href = 'data/data.html'
  ..onLoad.listen(initQuotes);
  document.head.append(dataLink);

  scene = querySelector('.scene')..onClick.listen(turn);
  cube = querySelector('.cube')..onTransitionEnd.listen((e){minimize(false);});
  viewBox = querySelector('#viewBox');
  picBox = querySelector('#picBox');
  qteBox = querySelector('#quoteBox');
  editor = querySelector('#editor');
  picInfo = querySelector('#picInfo');
//  iSaver = querySelector('#iSaver')..onChange.listen(saveData);
  btnUpdate = querySelector('#btnUpdate')..onClick.listen(update);
  btnSave = querySelector('#btnSave')..onClick.listen(saveClick);

  querySelector('#btnSearch').onClick.listen(search);

  window.onResize.listen(resize);

  querySelector('#btnEnter').onClick.listen(enter);

  init();
}

enter([e]){
  querySelector('#intro')
      ..classes.add('hidden')
      ..onTransitionEnd.listen((e){e.target.remove();});
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
    if (id != 'universe'){
      for(var side = 0; side < 4; side++){
        for(var i = 1; i <= (side.isEven ? iconsPerSide : iconsPerSide-2); i++){
          var iconId = '${id}${iconCnt++}'; // e.g. society1
          var imgUrl = 'img/i-${iconId}.png';
          var icon = new DivElement()
          ..id = 'icon-${iconId}'
          ..classes.addAll(['icon', 'side$side', id])
          ..onClick.listen(iconClick)
          ..style.transform = 'rotate(${rnd.nextInt(20)-10}deg)';
          catBox.append(icon);
          ImageElement image = new ImageElement(src: imgUrl);
          image.onLoad.listen((e){icon.style.backgroundImage = 'url($imgUrl)';}, onError: (e){icon.style.backgroundImage = 'url(img/icon.png)';});
  //        print('init[$side] $iconId');
        }
      }
    } else {
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

btnEndClick(e){
  picBox.style.backgroundImage = 'url(img/end.png)';
  picBox.classes.add('tvOff');
  querySelector('#btnEnd').style.display = 'none';
  var t = new Timer(endAnimDone, (){picBox.style.backgroundImage = 'url(img/universe.png)';});
}

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
          entries[i] = new PicData(pdId, q, a, p);
        }
      }
      quotes[id] = entries;
    }
  });
}

iconClick(MouseEvent e){
  if (e.toElement == curIcon) return;
  if (curIcon != null){
    curIcon.classes.remove('selected');
    showPicBox(false, curIcon.id);
    hideQteBox();
  }
  curIcon = e.toElement;
  curIcon.classes.add('selected');
  curIndex = int.parse(curIcon.id.replaceAll('icon-','').replaceAll('${iDs[curFace]}',''));
  print('click on: ${curIcon.id}');
  showPicBox(true, curIcon.id);
}

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

  minimize(false);
}

showBox(index, show){
  if (show)
    catBoxes[index].classes.remove('hidden');
  else {
    catBoxes[index].classes.add('hidden');
    showPicBox(false);
  }
}

showPicBox(show, [iconId]){
  var icon = querySelector('#$iconId');
  if (icon == null && show) return;

  print('[${iconId}]showPicBox($show)');

  if (picBox.classes.contains('tvOff')){
    picBox.classes.remove('tvOff');
    querySelector('#btnEnd').style.display = 'block';
  }
  if (show){
    picBox.style.backgroundImage = 'url(img/${icon.id.replaceAll('icon-','')}.png)';
    showQteBox();
  } else {
    picBox.style.backgroundImage = 'url(img/${iDs[curFace]}.png)';
    hideQteBox();
  }
}

hideQteBox(){
  print('hideQteBox');
  qteBox.classes.add('hidden');
  editor.classes.add('hidden');
  picInfo.classes.add('hidden');
}

showQteBox([e]){
  editor
  ..querySelector('#tQuote').value = ''
  ..querySelector('#tAuthor').value = ''
  ..querySelector('#tInfo').value = '';

  if ((qteBox.classes.contains('hidden') || (e is bool && e)) &&
     quotes[iDs[curFace]] != null &&
     quotes[iDs[curFace]][curIndex] != null){

    var picData = quotes[iDs[curFace]][curIndex];

    qteBox
    ..innerHtml = picData.asQteHtml
    ..classes.remove('hidden');

    editor
    ..querySelector('#tQuote').value = picData.quote.replaceAll('<br>', '\n')
    ..querySelector('#tAuthor').value = picData.author.replaceAll('<br>', '\n')
    ..querySelector('#tInfo').value = picData.info.replaceAll('<br>', '\n');

    picInfo
    ..innerHtml = picData.info.replaceAll('<br>', '\n')
    ..classes.remove('hidden');

  }

  if (canEdit){
    editor
    ..querySelector('#eId').text = iDs[curFace]
    ..querySelector('#eNum').text = curIndex.toString()
    ..querySelector('#ePicName').text = 'img/${iDs[curFace]}${curIndex}.png'
    ..classes.remove('hidden');
  }
}

turn([e]){
  minimize(true);
  showBox(curFace, false);
  hideQteBox();
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

minimize(bool small){
  if (small) {
    viewBox.classes.add('hidden');
    if (curIcon != null){
      curIcon.classes.remove('selected');
    }
    curIcon = null;
    showPicBox(false);
  } else {
    viewBox.classes.remove('hidden');
    querySelector('#vTitle').text = categories[curFace];
    picBox.style.backgroundImage = 'url(img/${iDs[curFace]}.png)';
    showPicBox(true);
    showBox(curFace, true);
  }
}

update([e]){
  var id = '${iDs[curFace]}${curIndex}';
  var quote = editor.querySelector('#tQuote').value.replaceAll('\n','<br>');
  var author = editor.querySelector('#tAuthor').value.replaceAll('\n','<br>');
  var info = editor.querySelector('#tInfo').value.replaceAll('\n','<br>');
  var picData = new PicData(id, quote, author, info);
  quotes[iDs[curFace]][curIndex] = picData;
  showQteBox(true);
  mustSave = true;
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
  String id, quote, author, info;
  PicData(this.id, this.quote, this.author, this.info){}
  String get asQteHtml => '${quote}<div class="qAuthor"><hr>$author</div>';
  String get asHtml => '\n        <div id="$id">\n          <div class="quote">$quote</div>\n          <div class="author">$author</div>\n          <div class="info">$info</div>\n        </div>';
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