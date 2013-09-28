mammouth.helpers = {
	slice_php_function: "function _m_slice($var, $start, $end) {if(gettype($var)=='string') {return substr($var, $start, $end);} elseif(gettype($var)=='array') {return array_slice($var, $start, $end);}}",
	len_php_function: "function _m_len($var) {if(gettype($var)=='string') {return strlen($var);} elseif(gettype($var)=='array') {return count($var);}}"
};