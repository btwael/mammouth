<?php
function mammouth($func, $arg1, $arg2){
	if ( $func == '+' ){
		if((is_string($arg1) && is_numeric($arg2))||(is_string($arg2) && is_numeric($arg1))){
			return $arg1.$arg2;
		} else {
			return $arg1+$arg2;
		}
	}
}