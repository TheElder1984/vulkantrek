shader_type sky;
render_mode use_debanding;
float hash(vec3 p) { p = fract(p * 0.3183099 + vec3(0.1,0.2,0.3)); p *= 17.0; return fract(p.x*p.y*p.z*(p.x+p.y+p.z)); }
float noise(vec3 p) {
 vec3 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}
void sky() {
 vec3 d=EYEDIR;
 float n=noise(d*3.0+2.0)*0.55+noise(d*7.0)*0.28+noise(d*17.0)*0.12+noise(d*40.0)*0.05;
 float band=pow(max(0.0,1.0-abs(d.y*1.8+d.x*0.5)),4.0);
 vec3 nebula=mix(vec3(0.018,0.09,0.14),vec3(0.18,0.065,0.22),noise(d*5.0));
 vec3 color=vec3(0.004,0.009,0.023)+nebula*pow(n,2.5)*band*2.0;
 vec3 cell=floor(d*700.0);
 float star=step(0.9985,hash(cell))*pow(max(0.0,1.0-length(fract(d*700.0)-0.5)*2.0),5.0);
 color += star*vec3(0.65,0.82,1.0)*3.0;
 COLOR=color;
}
