$(function(){
 for(var i=0;i<keymap.length;i++){
  for(var j=0;j<keymap[i].length;j++){
   var li=$(document.createElement('li')).text(keymap[i][j].name);
   li.data("used",false);
   if(keymap[i][j].code != null){
    li.attr("id",keymap[i][j].code);
   }else{
    li.addClass("ignored");
   }
   if(j==0){
    li.addClass("firstitem");
   }
   if(keymap[i][j].name.length<7){
    li.addClass("chara");
   }
   $("#keyboard").append(li);
  }
 }

 // システム指定済みのキーを設定
 var system_set=[1,59,61,62];
 system_set.forEach(function(val){
  var li=$("#"+val);
  li.data("used",true);
  li.css("backgroundColor","OrangeRed");
  li.attr({title: "System used"});
 });

 // マイクラの設定キーマップ読み込み
 var profileName=(function(){
  var data=(location.href.split('?',2))[1].split('&');
  var datas={};
  data.forEach(function(str){
   var a=str.split('=',2);
   datas[a[0]]=a[1];
  });
  return datas.name;
 })();
 $.getJSON("options_key.json",{name: profileName },function(data){
  var colors=["LightGreen","LightPink","LightSalmon","LightSeaGreen","LightSkyBlue","LightSlateGray","LightSteelBlue","LightYellow","Lime","LimeGreen"];
  var colorMap={};
  var error="#ff0000";
  var process=function(data,name,color){
   if(data instanceof Object){
    for(i in data){
     arguments.callee(data[i],name+"."+i,color);
    }
   }else{
    var li=$("#"+data);
    if(li.length==0){
     $("#none_list").append(
      $(document.createElement('li')).text(name)
     );
     console.log(data);
    }
    if(li.data("used")){
     li.css("backgroundColor",error);
     var title=li.attr("title")+", "+name;
     li.attr({title: title});
    }else{
     li.css("backgroundColor",color);
     li.attr({title: name});
    }
    li.data("used",true);
   }
  };
  Object.keys(data).forEach(function(key,index){
   colorMap[key]=colors[index%colors.length];
  });
  for(key in data){
   var li=$(document.createElement('li'));
   li.css({backgroundColor: colorMap[key]});
   li.text(key);
   $("#colors").append(li);
   process(data[key],key,colorMap[key]);
  }
 });

 $(document).tooltip();
});
