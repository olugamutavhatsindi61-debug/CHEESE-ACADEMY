/* Big Cheese Academy - shared script */
var R=document.documentElement,$=function(i){return document.getElementById(i)};
try{var t=localStorage.getItem("bca-theme");if(t)R.setAttribute("data-theme",t)}catch(e){}
$("tg").onclick=function(){var d=R.getAttribute("data-theme")==="dark"||(!R.getAttribute("data-theme")&&matchMedia("(prefers-color-scheme:dark)").matches);var n=d?"light":"dark";R.setAttribute("data-theme",n);try{localStorage.setItem("bca-theme",n)}catch(e){}};
$("mb").onclick=function(){$("lk").classList.toggle("open")};
addEventListener("scroll",function(){var h=R.scrollHeight-innerHeight;$("bar").style.width=(h>0?scrollY/h*100:0)+"%"},{passive:true});
var items=document.querySelectorAll(".rv");
if("IntersectionObserver" in window){var o=new IntersectionObserver(function(e){e.forEach(function(x){if(x.isIntersecting){x.target.classList.add("in");o.unobserve(x.target)}})},{threshold:.12});items.forEach(function(e){o.observe(e)})}else items.forEach(function(e){e.classList.add("in")});
/* ---- Database (Supabase) helpers: active only when js/config.js is filled in ---- */
var cfg=window.BCA||{};
function hdr(extra){var h={apikey:cfg.supabaseKey,Authorization:"Bearer "+cfg.supabaseKey};for(var k in extra)h[k]=extra[k];return h}
function db(table,row){if(!cfg.supabaseUrl)return Promise.resolve(null);
  return fetch(cfg.supabaseUrl+"/rest/v1/"+table,{method:"POST",keepalive:true,headers:hdr({"Content-Type":"application/json",Prefer:"return=minimal"}),body:JSON.stringify(row)}).then(function(r){return r.ok}).catch(function(){return false})}
function upFile(file){if(!cfg.supabaseUrl||!file)return Promise.resolve(null);
  var path=(crypto.randomUUID?crypto.randomUUID():Date.now())+"-"+file.name.replace(/[^\w.\-]/g,"_");
  return fetch(cfg.supabaseUrl+"/storage/v1/object/applications/"+path,{method:"POST",headers:hdr({"Content-Type":file.type||"application/octet-stream"}),body:file}).then(function(r){return r.ok?path:null}).catch(function(){return null})}
var f=$("f");
if(f){
  var plan=new URLSearchParams(location.search).get("plan");
  if(plan){var k=$("k");for(var i=0;i<k.options.length;i++){if(k.options[i].text===plan)k.selectedIndex=i}}
  f.onsubmit=function(e){e.preventDefault();var m="Hi Big Cheese Academy, I\u2019d like to enrol.\nName: "+$("n").value+"\nPhone: "+$("p").value+"\nGrade: "+$("g").value+"\nPackage: "+$("k").value+"\nSubject(s): "+$("s").value+"\nMessage: "+$("m").value;db("enrolments",{full_name:$("n").value,phone:$("p").value,grade:parseInt($("g").value.replace(/\D/g,"")),package_name:$("k").value,subjects:$("s").value,message:$("m").value});window.open("https://wa.me/27767642609?text="+encodeURIComponent(m),"_blank")};
}

var af=$("a");
if(af){
  af.onsubmit=function(e){
    e.preventDefault();
    var b=$("ab"),st=$("as"),g=function(n){return af.elements[n].value.trim()},err=function(t){st.className="err";st.textContent=t};
    var docs=[],total=0,ins=af.querySelectorAll("input[type=file]");
    for(var i=0;i<ins.length;i++){var f0=ins[i].files[0];if(!f0)continue;
      if(f0.size>5*1024*1024){return err(ins[i].dataset.doc+" is larger than 5 MB. Please attach a smaller file.")}
      total+=f0.size;docs.push({key:ins[i].dataset.key,file:new File([f0],ins[i].dataset.doc+"-"+f0.name.replace(/[^\w.\-]/g,"_"),{type:f0.type})})}
    var hasLetter=docs.some(function(x){return x.key==="motivation_path"});
    if(!g("Motivation")&&!hasLetter){return err("Please write why you want to tutor with us, or upload a motivation letter.")}
    if(!cfg.supabaseUrl&&total>5*1024*1024){return err("Your files total more than 5 MB. Please attach smaller files.")}
    b.disabled=true;b.textContent="Sending…";st.className="";st.textContent="";
    var d=new FormData(af);
    d.append("_subject","New tutor application | Big Cheese Academy");d.append("_template","table");d.append("_captcha","false");
    if(cfg.supabaseUrl){d.append("Uploaded documents",docs.map(function(x){return x.file.name}).join(", ")||"none")}
    else{docs.forEach(function(x){d.append("attachment",x.file)})}
    var saved=!cfg.supabaseUrl?Promise.resolve(null):Promise.all(docs.map(function(x){return upFile(x.file).then(function(p){return [x.key,p]})})).then(function(up){
      var row={full_name:g("Full name"),email:g("Email"),phone:g("Phone"),qualification:g("Qualification"),institution:g("Institution"),grades:g("Grades"),subjects:g("Subjects"),experience:g("Experience"),availability:g("Availability"),motivation:g("Motivation")||null};
      for(var k=0;k<up.length;k++){if(!up[k][1])return false;row[up[k][0]]=up[k][1]}
      return db("tutor_applications",row)});
    var mailed=fetch("https://formsubmit.co/ajax/tebugoblessing26@gmail.com",{method:"POST",body:d,headers:{Accept:"application/json"}})
      .then(function(r){return r.json()}).then(function(r){return r.success===true||r.success==="true"}).catch(function(){return false});
    Promise.all([saved,mailed]).then(function(x){
      var ok=cfg.supabaseUrl?x[0]===true:x[1];
      if(ok){af.reset();st.className="ok";st.textContent="Thank you! Your application has been sent. We will be in touch soon."}
      else{st.className="err";st.innerHTML="Sorry, that didn\u2019t send. Please check your files and try again, or email your details to <a href=\"mailto:tebugoblessing26@gmail.com\">tebugoblessing26@gmail.com</a>."}
      b.disabled=false;b.textContent="Submit Application"});
  };
}
