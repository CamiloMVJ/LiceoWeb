const assert=require('node:assert/strict');
const fs=require('node:fs');
const vm=require('node:vm');
const path=require('node:path');
const script=fs.readFileSync(path.join(__dirname,'../../LiceoWeb/wwwroot/js/flujo-academico.js'),'utf8');
let submits=0;
const form={elements:{pensum:{value:'10'},grupo:{value:'100'}},addEventListener(t,f){this.change=f;},requestSubmit(){submits++;}};
const mode={value:'Cuantitativa',addEventListener(t,f){this.change=f;}};
const numeric={dataset:{modoCampos:'Cuantitativa'},inputs:[{},{}],querySelectorAll(){return this.inputs}};
const scale={dataset:{modoCampos:'Cualitativa'},inputs:[{}],querySelectorAll(){return this.inputs}};
vm.runInNewContext(script,{document:{querySelector:q=>q==='[data-contexto-academico]'?form:q==='[data-modo-evaluacion]'?mode:null,querySelectorAll:()=>[numeric,scale]}});
assert.equal(numeric.hidden,false);assert.equal(scale.hidden,true);assert.equal(scale.inputs[0].disabled,true);
form.change({target:{name:'anio'}});assert.equal(form.elements.pensum.value,'0');assert.equal(form.elements.grupo.value,'0');
form.elements.pensum.value='20';form.elements.grupo.value='200';form.change({target:{name:'pensum'}});assert.equal(form.elements.pensum.value,'20');assert.equal(form.elements.grupo.value,'0');assert.equal(submits,2);
mode.value='Cualitativa';mode.change();assert.equal(numeric.hidden,true);assert.equal(numeric.inputs[0].disabled,true);assert.equal(scale.hidden,false);assert.equal(scale.inputs[0].disabled,false);
vm.runInNewContext(script,{document:{querySelector:()=>null}});
console.log('PASS cambios de año/plan, envío del contexto, modos de evaluación y páginas sin controles');
const modalidad={selectedOptions:[],addEventListener(_,fn){this.change=fn},form:{addEventListener(){}}};
const grado={value:'',replaceChildren(o){this.items=[o];this.value=''},append(o){this.items.push(o)}};
const opciones=['preescolar','primaria','secundaria'].map(clave=>({dataset:{modalidad:clave},cloneNode(){return this}}));
const template={content:{querySelectorAll:()=>opciones}};
vm.runInNewContext(script,{Option:function(text,value){this.value=value},document:{querySelector:q=>({'[data-modalidad-plan]':modalidad,'[data-grado-plan]':grado,'[data-grados-plan]':template})[q]}});
for(const opcion of opciones){
 modalidad.selectedOptions=[opcion];grado.value='grado anterior';modalidad.change();
 assert.equal(grado.value,'');assert.equal(grado.disabled,false);assert.equal(grado.items.length,2);assert.equal(grado.items[1],opcion);
}
modalidad.selectedOptions=[];modalidad.change();assert.equal(grado.disabled,true);assert.equal(grado.items.length,1);
console.log('PASS filtro por modalidad y limpieza del grado anterior');
