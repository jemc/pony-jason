class Parser
  var _notify: ParserNotify = ParserNotifyNone
  var _source: String box   = ""
  var _offset: USize        = 0
  var _offset_start: USize  = 0
  var _abort: Bool          = false
  
  // TODO: allow configuring to skip capture of upcoming number or string.
  
  var last_number: (I64 | F64) = I64(0)
  var last_string: String = ""
  
  new ref create() => None
  
  fun ref _set_defaults() =>
    _offset       = 0
    _offset_start = 0
    _abort        = false
    last_number   = I64(0)
    last_string   = ""
  
  fun ref parse(
    source': String box,
    notify': ParserNotify = ParserNotifyNone)
  ? =>
    (_source, _notify) = (source', notify')
    _set_defaults()
    if _detect_empty() then return end
    _parse_data()?
    _verify_final()?
  
  fun source(): String box => _source
  fun token_start(): USize => _offset_start
  fun token_end(): USize => _offset
  
  fun describe_error(): String =>
    if _offset < _source.size()
    then "invalid JSON at byte offset: "          + _offset.string()
    else "unfinished JSON; stream ends at byte: " + _source.size().string()
    end
  
  fun ref abort() => _abort = true // TODO: include a message?
  
  fun ref _has_next(): Bool => _offset < _source.size()
  
  fun ref _next(): U8? => let b = _peek()?; _advance(); b
  
  fun _peek(): U8? => _source(_offset)?
  
  fun _peek_softly(): U8 => try _source(_offset)? else ' ' end
  
  fun ref _eat(b: U8)? => if b != _source(_offset)? then error end; _advance()
  
  fun ref _advance(n: USize = 1) => _offset = _offset + n
  
  fun ref _rewind(n: USize = 1) => _offset = _offset - n
  
  fun ref _pre_token() => _offset_start = _offset
  
  fun ref _yield(t: Token)? =>
    _notify(this, t)
    if _abort then error end
  
  fun ref _skip_whitespace() =>
    while _has_next() do
      match _peek_softly() | ' ' | '\r' | '\t' | '\n' => _advance()
      else return
      end
    end
  
  fun ref _detect_empty(): Bool =>
    _skip_whitespace()
    not _has_next()
  
  fun ref _verify_final()? =>
    _skip_whitespace()
    if _has_next() then error end
  
  fun ref _parse_data()? =>
    _skip_whitespace()
    _pre_token()
    match _peek()?
    | 'n' => _advance(); _eat('u')?; _eat('l')?; _eat('l')?;             _yield(TokenNull)?
    | 't' => _advance(); _eat('r')?; _eat('u')?; _eat('e')?;             _yield(TokenTrue)?
    | 'f' => _advance(); _eat('a')?; _eat('l')?; _eat('s')?; _eat('e')?; _yield(TokenFalse)?
    | '"' => _parse_string()?
    | '{' => _parse_object()?
    | '[' => _parse_array()?
    | '-' => _parse_number()?
    | let b: U8 if (b >= '0') and (b <= '9') => _parse_number()?
    else error
    end
  
  fun ref _parse_array()? =>
    _advance() // past the opening bracket
    _yield(TokenArrayStart)?
    _skip_whitespace()

    if _peek()? == ']' then
      _pre_token()
      _advance()
      _yield(TokenArrayEnd)?
      return
    end
    
    while true do
      _parse_data()?; _skip_whitespace()
      _pre_token() // prepare for possible array end token
      match _next()?
      | ',' => _skip_whitespace()
      | ']' => break
      else _rewind(); error
      end
    end
    
    _yield(TokenArrayEnd)?
  
  fun ref _parse_object()? =>
    _advance() // past the opening bracket
    _yield(TokenObjectStart)?
    _skip_whitespace()
    
    if _peek()? == '}' then
      _pre_token()
      _advance()
      _yield(TokenObjectEnd)?
      return
    end
    
    while true do
      _eat('"')?; _rewind(); _parse_string(true)?; _skip_whitespace()
      _eat(':')?; _parse_data()?; _skip_whitespace()
      _pre_token(); _yield(TokenPairPost)?
      match _next()?
      | ',' => _skip_whitespace()
      | '}' => break
      else _rewind(); error
      end
    end
    
    _yield(TokenObjectEnd)?
  
  fun ref _parse_number()? =>
    _yield(TokenNumberPre)?
    last_number = _read_number()?
    _yield(TokenNumber)?
  
  fun ref _read_number(): (I64 | F64)? =>
    let sign: I64 =
      if _peek_softly() == '-' then _advance(); -1 else 1 end
    
    let integer = _read_number_digits()?
    
    var dot: F64 = 0
    let has_dot = (_peek_softly() == '.')
    if has_dot then _advance(); dot = _read_number_digits_as_fractional()? end
    
    var exp: I64 = 0
    let has_exp = match _peek_softly() | 'e' | 'E' => true else false end
    if has_exp then
      _advance()
      let exp_negative =
        match _peek()?
        | '+' => _advance(); false
        | '-' => _advance(); true
        else false
        end
      exp = _read_number_digits()?
      if exp_negative then exp = -exp end
    else 0
    end
    
    if has_dot or has_exp
    then sign.f64() * (integer.f64() + dot) * (F64(10).pow(exp.f64()))
    else sign * integer
    end
  
  fun ref _read_number_digits_as_fractional(): F64? =>
    let orig_offset = _offset
    let integer = _read_number_digits()?
    (integer.f64() / F64(10).pow((_offset - orig_offset).f64()))
  
  fun ref _read_number_digits(): I64? =>
    var value: I64 = 0
    var byte = _peek()?
    while _is_number_digit(byte) do
      value = (value * 10) + (byte - '0').i64()
      _advance()
      byte = _peek_softly()
    end
    value
  
  fun tag _is_number_digit(b: U8): Bool => (b >= '0') and (b <= '9')
  
  fun ref _parse_string(is_key: Bool = false)? =>
    _advance() // past the opening quote
    _pre_token()
    _yield(if is_key then TokenKeyPre else TokenStringPre end)?
    
    var buf = recover String end
    while true do
      match _next()?
      | '"'  => break
      | '\\' => buf = _push_escape_seq(consume buf)?
      | let b: U8 => buf.push(b)
      end
    end
    last_string = consume buf
    
    _rewind()
    _yield(if is_key then TokenKey else TokenString end)?
    _advance()
  
  fun ref _push_escape_seq(buf: String iso): String iso^? =>
    match _next()?
    | '"'  => (consume buf).>push('"')
    | '\\' => (consume buf).>push('\\')
    | '/'  => (consume buf).>push('/')
    | 'b'  => (consume buf).>push(0x08)
    | 't'  => (consume buf).>push(0x09)
    | 'n'  => (consume buf).>push(0x0a)
    | 'f'  => (consume buf).>push(0x0c)
    | 'r'  => (consume buf).>push(0x0d)
    | 'u'  => (consume buf).>append(_read_unicode_seq()?)
    else error
    end
  
  fun ref _read_unicode_seq(): String? =>
    // We've already read the initial "\u" bytes, so start reading the digits.
    let value = _read_unicode_value()?
    
    if (value < 0xD800) or (value >= 0xE000) then
      // If the value we read is a valid single UTF-16 value, return it now.
      recover String.from_utf32(value) end
    else
      // Otherwise, it is half of a surrogate pair, so we expect another half,
      // in another unicode escape sequence immediately following this one.
      _eat('\\')?; _eat('u')?
      let value_2 = _read_unicode_value()?
      
      if (value < 0xDC00) and (value_2 >= 0xDC00) and (value_2 < 0xE000) then
        // If the two values make a valid pair, return the combined value.
        let combined = 0x10000 + ((value and 0x3FF) << 10) + (value_2 and 0x3FF)
        recover String.from_utf32(combined) end
      else
        // The two are an invalid pair. Backtrack to show the error position.
        _rewind(4)
        error
      end
    end
  
  fun ref _read_unicode_value(): U32? =>
    var value: U32 = 0
    var count: U8  = 0
    
    while (count = count + 1) < 4 do
      var b = _next()?
      let digit =
        if     (b >= '0') and (b <= '9') then b - '0'
        elseif (b >= 'a') and (b <= 'f') then (b - 'a') + 10
        elseif (b >= 'A') and (b <= 'F') then (b - 'A') + 10
        else _rewind(); error
        end
      
      value = (value * 16) + digit.u32()
    end
    
    value
