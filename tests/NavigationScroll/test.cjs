const { readFileSync } = require('node:fs');
const { resolve } = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const script = readFileSync(resolve(__dirname, '../../LiceoWeb/wwwroot/js/site.js'), 'utf8');
const key='liceo:navegacion:scroll:v1';
function page(href, data=null, type='navigate', blocked=false) {
 const values=new Map(data?[[key,JSON.stringify(data)]]:[]), events={}, calls=[];
 const location=new URL(href), containers={'.liceo-sidebar':{scrollTop:100,scrollLeft:0},'.liceo-main':{scrollTop:200,scrollLeft:0}};
 for(const [name,node] of Object.entries(containers))node.scrollTo=p=>calls.push([name,p.top]);
 const window={scrollX:0,scrollY:850,addEventListener:(n,fn)=>events[n]=fn,scrollTo:p=>calls.push(['window',p.top])};
 const document={readyState:'complete',querySelector:n=>containers[n],addEventListener:(n,fn)=>events[n]=fn};
 const sessionStorage={getItem:k=>{if(blocked)throw Error();return values.get(k)||null;},setItem:(k,v)=>{if(blocked)throw Error();values.set(k,v);},removeItem:k=>values.delete(k)};
 vm.runInNewContext(script,{URL,Date,Number,Object,JSON,location,window,document,sessionStorage,performance:{getEntriesByType:()=>[{type}]},requestAnimationFrame:fn=>fn()});
 const click=(url,extra={})=>events.click({button:0,target:{closest:()=>({href:url,target:'',hasAttribute:()=>false})},...extra});
 return {values,calls,click};
}
const origin='https://liceo.test';let count=0;
function check(name,fn){fn();count++;console.log('PASS '+name);}
let state;
check('Guardar desplazamiento al cambiar módulo',()=>{const p=page(origin+'/Estudiantes');p.click(origin+'/Finanzas/Cuenta');state=JSON.parse(p.values.get(key));assert.equal(state.window.y,850);assert.equal(state.containers['.liceo-sidebar'].y,100);});
check('Restaurar ventana y contenedores',()=>{const p=page(origin+'/Finanzas/Cuenta',state);assert.equal(p.calls.length,3);assert.equal(p.calls[0][1],850);assert.equal(p.values.has(key),false);});
check('No restaurar tras redirección a login',()=>assert.equal(page(origin+'/Identity/Account/Login',state).calls.length,0));
check('No intervenir en atrás/adelante',()=>assert.equal(page(origin+'/Finanzas/Cuenta',state,'back_forward').calls.length,0));
check('No intervenir en recarga',()=>assert.equal(page(origin+'/Finanzas/Cuenta',state,'reload').calls.length,0));
check('Respetar anclas',()=>assert.equal(page(origin+'/Finanzas/Cuenta#detalle',state).calls.length,0));
check('No guardar enlaces externos',()=>{const p=page(origin+'/Estudiantes');p.click('https://otro.test/');assert.equal(p.values.size,0);});
check('Respetar nueva pestaña por Ctrl',()=>{const p=page(origin+'/Estudiantes');p.click(origin+'/Finanzas/Cuenta',{ctrlKey:true});assert.equal(p.values.size,0);});
check('Almacenamiento bloqueado no rompe navegación',()=>page(origin+'/Estudiantes',null,'navigate',true).click(origin+'/Finanzas/Cuenta'));
check('Estado vencido no restaura',()=>assert.equal(page(origin+'/Finanzas/Cuenta',{...state,time:Date.now()-60000}).calls.length,0));
console.log(`${count} pruebas aprobadas.`);
