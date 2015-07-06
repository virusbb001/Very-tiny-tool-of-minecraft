$(function(){
 // プロファイル名
 var profileName=(function(){
  var data=(location.href.split('?',2))[1].split('&');
  var datas={};
  data.forEach(function(str){
   var a=str.split('=',2);
   datas[a[0]]=a[1];
  });
  return datas.name;
 })();

 $.getJSON("modlist.json",{name: profileName}, function(data){
  var processMod=function(mod,parent_ul){
   var list=[];
   var proc=function(hash){
    if(hash.url){
     list.push(hash.url);
    }
   }
   if(mod instanceof Array){
    for(var i=0;i<mod.length;i++){
     proc(mod[i]);
    }
   }else{
    proc(mod);
   }
   list=list.filter(function(val,index,self){
    return self.indexOf(val)===index;
   });
   list.forEach(function(elem){
    var li=$(document.createElement('li')).append($(document.createElement('a')).attr({href: elem}).text(elem));
    parent_ul.append(li);
   });
  };
  var process=function(hash,parent_ul){
   for(var key in hash){
    if(key.match(/\/$/)){
     // ディレクトリ
     var li=$(document.createElement('li')).text(key);
     parent_ul.append(li);
     var ul=$(document.createElement('ul'));
     parent_ul.append(ul);
     process(hash[key],ul);
    }else if(key.match(/\.(zip|jar)$/)){
     var li=$(document.createElement('li')).text(key);
     parent_ul.append(li);
     var ul=$(document.createElement('ul'));
     if(hash[key]!=null){
      processMod(hash[key],ul);
     }else{
      ul.append($(document.createElement('li')).text("mcmod.info not found").css({color:"#ff0000"}));
     }
     parent_ul.append(ul);
    }
   }
  }
  var parent_ul=$("#mod_list");
  process(data,parent_ul);
 });
});
