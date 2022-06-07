// Use this code to make it work offline:
//     https://gist.github.com/kosamari/7c5d1e8449b2fbc97d372675f16b566e


expressions = _ a:statements _ {
	
	return "using TypeScript; "+a;
}

statements = head:statement tail:(_ statement)* {
      return tail.reduce(function(result, element) {
        return result + element[1];
      }, head);
    }

abstract_method = "abstract" __ a:interface_method _ ";" {return function(name1){return a+";";};}

interface_method = name:var_name _ type_params:type_params_string "(" _ b:function_parameters _ ")" _ t1:return_type_string {
		return "public " + t1 +" "+ name+"("+b+")";
	}

interface_statement = interface_method
	/ function_parameter

interface_statements = head:interface_statement ";" tail:(_ interface_statement _ ";")* {
      return tail.reduce(function(result, element) {
        return result +";"+ element[1] + ";";
      }, head);
    }
    
class_statements = head:class_statement tail:( _ class_statement)* {
      return tail.reduce(function(result, element) {
        return function(name){return result(name) + element[1](name)};
      }, head);
    }

class_method = acc:access_modifier static_str:static_string name:var_name _ type_params:type_params_string "(" _ params:function_parameters _ ")" _ t1:return_type_string "{" _ c:statements _ "}" {
		return function(name1){return static_str+t1+" "+name+"("+params+"){"+c+"}";}
	}

type_params_string = "<" _ t1:type_parameters _ ">" _ {return "<"+t1+">";} / "" {return "";}	
return_type_string = ":" _ t1:type _ {return t1;}  / "" {return "dynamic";}

constructor = "constructor" _ "(" _ params:function_parameters _ ")" _ "{" _ body:statements _ "}" {
	return function(name1){return "public "+name1+"("+params+"){"+body+"}";};
}

class_statement = constructor / abstract_method / class_method  / a:class_member _ ";" {return function(name1){return a(name1) + ";"}}

class_member = s1:static_string a:var_name _ ":" _ b:type {
	return function(name1){return s1+b+" "+a;};
}

access_modifier = "export" __ {return "public "} / "" {return "private "}

super_class_string = ( _ "extends" _ v:var_name  v1:(__ "implements" __ v2:var_name {return v2;} / "" {return "";}) {return ": "+v+","+v1} / "" {return "";})
implements_string = ( _ "implements" _ v:var_name {return ":"+v;} / "" {return "";})



class_=
	"type" __ a:var_name _ "=" _ b:type ";" {return "\n#define "+a+" "+b+"\n";}
	/ acc:access_modifier ("abstract" __ / "") "class" __ name:var_name type_params:type_params_string  super_class:(super_class_string / implements_string) _ "{" _ a4:class_statements _ "}" {
		let to_return = "";
		let class_body = a4(name);
		to_return = acc+"class "+name+type_params+super_class+"{"+class_body+"};";
		return to_return;
	}
	/ acc:access_modifier "interface" __ name:var_name type_params:type_params_string super_class:super_class_string implements_str:implements_string _ "{" _ a:interface_statements _ "}"
	{ return acc + "interface "+name+super_class+implements_str+"{"+a+"}";}
    / "enum" __ a:var_name __ "{" __ b:identifiers __ "}" {return "enum "+a+"{"+b+"}"}


static_string = "static" __ {return "static ";} / "" {return "";}


statement =
	a1:statement_ {return a1;}
	/ a1:statement_with_semicolon _ (";" / "") {
		return a1+";"
	}
	

statement_
    =
    class_
    / "while" _ "(" _ a3:e _ ")" _ a5:bracket_statements {return ["while(",a3,"){",a5,"}"].join("");}
    / "do" _ a2:bracket_statements _ "while" _ "(" _ a5:e _ ")" _ ";" {return ["do ",a2," while(",a5,");"].join("");}
    / "switch" _ "(" _ a3:e _ ")" _ "{" _ a6:case_statements _ "}" {return ["switch(",a3,"){",a6,"}"].join("");}
    / "for" _ "(" _ a3:statement_with_semicolon _ ";" _ a5:e _ ";" _ a7:statement_with_semicolon _ ")" _ a9:bracket_statements {return "for("+a3+";"+a5+";"+a7+"){"+a9+"}";}
    / "for" _ "(" _ ("let" / "var") _ item:var_name __ "of" __ the_arr:var_name _ ")" _ body:bracket_statements {
		return "for("+the_arr+")|"+item+"|{"+body+"})";
	}
    / "if" _ "(" _ a3:e _ ")" _ a5:bracket_statements _ a6:elif { return ["if ",a3,"{",a5,"}",a6].join("");}
	/ "if" _ "(" _ a3:e _ ")" _ a5:bracket_statements { return ["if ",a3,"{",a5,"}"].join("");}
    / "function" __ name:var_name _ type_params:type_params_string "(" _ b:identifiers _ ")" _ t1:return_type_string "{" _ c:statements _ "}" {
		return t1+" "+name+"("+b+"){"+c+"}"
	}

type_parameters = head:type tail:(_ (',') _ type)* {
      return tail.reduce(function(result, element) {
        return result + ", " + element[3];
      }, head);
    }

identifiers = head:var_name tail:(_ (',') _ var_name)* {
      return tail.reduce(function(result, element) {
        return result + element[1] + element[3];
      }, head);
    }

case_statement= "case" __ a2:e _ ":" _ a4:statements _ "break" _ ";" {return ["case ",a2,":",a4,"break;"].join("")}

case_statements_ = head:case_statement tail:(_ case_statement)* {
      return tail.reduce(function(result, element) {
        return result + element[1];
      }, head);
    }

case_statements= a1:case_statements_ a2:(_ default_statement / "") {return a1+a2};

default_statement = "default" _ ":" _ a4:statements {return ["default:",a4].join("")}

const_or_var = ("let" / "var") {return "";} / "const" {return "const "};

statement_with_semicolon
   = 
   "return" __ a2:e  {
		return "return "+a2;
	}
		
   / "return"  {return "return";}
   / c1:const_or_var __ name:var_name _ ":" _ t1:type _ "=" _ val:e {
		return c1+t1+" " + name + " = "+val;
   }
   / c1:const_or_var __ name:var_name _ "=" _ val:e {
		return c1+"dynamic " + name + " = "+val;
   }
   / name:assignable _ a2:"=" _ val:e {
		return name+a2+val;
   }
   / a1:assignable _ a2:("++" / "--") {return a1+a2;}
   / a1:assignable _ a2:("+=" / "%=" / "-=" / "*=" / "/=") _ a3:e {return a1+a2+a3;}
   / var_name


type =  t1:type_ "[" "]" {return t1+"[]";} / "Array" "<" t1:type_ ">" {return type+"[]";} / type_
type_ = name:var_name {return name;}
types = head:type tail:(_ (',') _ type)* {
      return tail.reduce(function(result, element) {
        return result + element[1] + element[3];
      }, head);
    } / "" {return "";}

e
    =
     a1:e6 _ "?" _ a3:e6 _ ":" _ a5:e {return "("+a1+"?"+a3+":"+a5+")";}
    /e6


e6
  = head:e5 tail:(_ ("||") _ e5)* {
      let to_return = tail.reduce(function(result, element) {
        let to_return = result + " || " + element[3]; return to_return;
      }, head);
      return to_return;
    }

e5
  = head:e4 tail:(_ ("&&") _ e4)* {
      let to_return = tail.reduce(function(result, element) {
        let to_return = result + " && " + element[3]; return to_return;
      }, head);
      return to_return;
    }

e4_op= '!==' {return "!=";} / "===" {return "==";}

e4
  = head:e3 tail:(_ ('<='/'<'/'>='/'>'/e4_op) _ e3)* {
      let to_return = tail.reduce(function(result, element) {
        let to_return = result + element[1] + element[3]; return to_return;
      }, head);
      return to_return;
    }

e3
  = head:e2 tail:(_ ('>>'/'<<') _ e2)* {
      let to_return = tail.reduce(function(result, element) {
        return result + element[1] + element[3];
      }, head);
      return to_return;
    }

e2
  = head:e1 tail:(_ ('+'/'-') _ e1)* {
        let to_return = tail.reduce(function(result, element) {
        let to_return = result + element[1] + element[3];
        return to_return;
      }, head);
      return to_return;
    }
    
e1= head:not_expr tail:(_ ('*' / '/' / '%') _ not_expr)* {
      let to_return = tail.reduce(function(result, element) {
        let to_return = result + element[1] + element[3];
        return to_return;
      }, head);
      return to_return;
    }
    / '-' _ a2:e1
        {let to_return = "-"+a2; return to_return;}

assignable = head:dot_expr tail:(_ access_array_)* {
      let to_return = tail.reduce(function(result, element) {
        let to_return = result + element[1];
        return to_return;
      }, head);
    }

access_array = head:function_call tail:(_ access_array_)* {
      let to_return = tail.reduce(function(result, element) {
        let to_return = result + element[1];
        return to_return;
      }, head);
      return to_return;
    }

access_array_ = "[" _ a:e _ "]" {let to_return = "["+a+"]"; return to_return;}

function_call
  = head:callable type_params:type_params_string tail:(_ function_call_ / "") {
	  var split_head = head.split(".");
      if(split_head.length === 2 && split_head[0] === "compiled_Math" && (["compiled_round","compiled_sin","compiled_asin","compiled_acos","compiled_atan","compiled_asinh","compiled_acosh","compiled_atanh","compiled_min","compiled_max","compiled_cos","compiled_tan","compiled_sinh","compiled_cosh","compiled_tanh","compiled_abs","compiled_floor","compiled_ceil","compiled_exp","compiled_pow","compiled_log","compiled_log2","compiled_sqrt","compiled_trunc","compiled_sign"].indexOf(split_head[1]) !== -1)){
	      let to_return = split_head[1].substring("compiled_".length,split_head[1].length) + tail[1];
	      return to_return;
      }
      else if(head === "compiled_Number"){
		  let to_return = "float" + tail[1];
	      return to_return;
      }
      else if(head === "compiled_typeof"){
		  return "decltype"+tail[1];
      }
      else if(head === "compiled_Boolean"){
		  let to_return = "float" + tail[1];
	      return to_return;
      }
      else if(tail.length > 0){
		return head+tail[1];
	  }
	  else{
	    return head;
	  }
    }

function_call_ = "(" _ a2:exprs _ ")" {return "("+a2+")";}

not_expr= a1:"!" _ a2:access_array {let to_return = "!"+a2; return to_return;} / access_array

object_member = a1:var_name _ ":" _ e1:e {return a1+"="+e1;}

object_members = head:object_member tail:(_ (',') _ object_member)* {
      return tail.reduce(function(result, element) {
        return result+","+element[3];
      }, head);
    } / "" {return "";}
    
enum_member = a1:var_name e1:(_ "=" _ e1:e / "") {
	if(e1.length > 0)
	return +a1+"="+e1[3];
	return a1;
}

enum_members = head:enum_member tail:(_ (',') _ enum_member)* {
      return tail.reduce(function(result, element) {
        return result+","+element[3];
      }, head);
    } / "" {return "";}


anonymous_type = "{" _ a:object_members _ "}" {
	  return "new {"+a+"}"
	}

anonymous_function = "function" _ "(" _ params:function_parameters _ ")" _ "{" _ body:statements _ "}" {
		return "(("+params+") => {"+body+"})"
	}
	/ "function" _ "(" _ params:function_parameters _ ")" _ ":" _ t1:type _ "{" _ body:statements _ "}" {
		return "(("+params+") => {"+body+"})"
	}

initializer_list = "[" a2:array_exprs "]" {return "new[]{"+a2[1]+"}";}

anonymous_class = "class" _ super_class:super_class_string _ "{" _ a4:class_statements _ "}" {
		return "new {"+a4(name)+"}"; //anonymous type
	}

new_instance = "new" __ a:dot_expr "(" b:exprs ")" {return a+".init("+b+")"}

callable=
	a:NUMBER {return a;}
	/ "new" __ a:dot_expr "(" b:exprs ")" {return a+"("+b+")"}	
	/ dot_expr

dot_expr_ = 
	"(" _ a2:e _ ")" {let to_return  ="("+a2+")"; return to_return;}
	/ initializer_list
	/ anonymous_type
	/ anonymous_function
	/ anonymous_class
	/ var_name
	/ STRING_LITERAL

dot_expr = head:dot_expr_ tail:(_ v1)* {
      let to_return = tail.reduce(function(result, element) {
        return result + element[1];
      }, head);
      return to_return;
	  //else return to_return;
    }

v1 = a:('.') _ b:var_name {return a+b;} / function_call_ / access_array_


function_parameter = a1:var_name _ ":" _ t1:type _ "=" _ d:e  {return [t1+" "+a1+" = " + d];}
/ a1:var_name _ "=" _ d:e  {return ["dynamic "+a1+" = " + d];}
/ a1:var_name _ ":" _ t1:type {return [t1+" "+a1];}
/ a1:var_name {return ["dynamic "+a1];}

function_parameters = head:function_parameter tail:(_ (',') _ function_parameter)* {
      return (tail.reduce(function(result, element) {
        return result.concat(element[3]);
      }, head)).map(function(value,index){
		  return value;}).join(",");
    } / "" {return "";}

exprs = head:e tail:(_ (',') _ e)* {
      return tail.reduce(function(result, element) {
        return result + element[1] + element[3];
      }, head);
    } / "";

array_exprs = head:e tail:(_ (',') _ e)* {
      return [head,tail.reduce(function(result, element) {
        return result + element[1] + element[3];
      }, head)];
    } / "";

else_if= "else" __ "if" / "elseif";
elif = head:elif_ tail:(_ elif_)* {
      return tail.reduce(function(result, element) {
        return result + element[1] + element[3];
      }, head);
    } / "else" a2:bracket_statements {return "else {"+a2+"}";}

elif_ = a1:else_if _ "(" _ a3:e _ ")" _ a5:bracket_statements {return "else if("+a3+"){"+a5+"}";}

var_name= name:IDENTIFIER {
let to_return = "";
if(name == "this") to_return = "self"; else if(["true","false","undefined","void","break","continue","arguments"].includes(name)) to_return = name; else to_return = (name==="string"?"string":name === "number"?"double":name==="boolean"?"bool":name==="any"?"auto":"compiled_"+name);
return to_return;
}

bracket_statements= "{" _ a2:statements _ "}" {return a2;} / a1:statement_with_semicolon _ ";" {return a1+";";}

IDENTIFIER = [a-zA-Z_][a-zA-Z0-9_]* {return text();}
STRING_LITERAL = '"' @$([^"\\] / "\\" .)* '"'

NUMBER = a:Integer b:NUMBER_ {if(b==="") b = "0"; let to_return =  a+"."+b; return to_return;}
NUMBER_ = "." a:Integer {return a;} / ("." / "") {return "";}

Integer "integer"
  = _ [0-9]+ { return text(); }

_
  = [ \t\n\r]*
  
__
  = [ \t\n\r] [ \t\n\r]*
