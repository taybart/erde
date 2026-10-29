local compile = require('erde.compile')
local lib = require('erde.lib')

local options = { experiments = { match = true } }

local function assert_match(expected, source)
  assert.are.same(expected, lib.run(source, options))
end

-- -----------------------------------------------------------------------------
-- Match (experimental)
-- -----------------------------------------------------------------------------

spec('match #5.1+', function()
  local kind = [[
    local MOVIE = 'movie'
    local function kind(mode, count = 0) {
      match mode {
        MOVIE => { return 'film' }
        'show' | 'series' => {
          return 'tv'
        }
        _ if count > 5 => { return 'many' },
        _ => { return 'other' }
      }
    }
  ]]

  assert_match('filmtvmanyother', kind .. "return kind('movie') .. kind('series') .. kind('x', 10) .. kind('x')")
  assert_match(3, 'local r = 0; match 3 { 1 | 2 => { r = 1 } 3 => { r = 3 } }; return r')
  assert_match('none', "local r = 'none'; match 'x' { 'a' => { r = 'a' } }; return r")
  assert_match('all', "local r; match 1 { _ => { r = 'all' } }; return r")
  assert_match(0, 'local r = 0; match 1 {}; return r')
end)

spec('match subject is evaluated once #5.1+', function()
  assert_match(1, 'local n = 0; local function f() { n += 1; return 2 } match f() { 1 => {} 2 => {} 3 => {} }; return n')
end)

spec('match break / continue #5.1+', function()
  assert_match(405, 'local s = 0; for i = 1, 6 { match i % 3 { 0 => { continue } 1 => { s += i } } s += 100 }; return s')
  assert_match(3, 'local s = 0; while true { s += 1; match s { 3 => { break } } }; return s')
end)

spec('match patterns #5.1+', function()
  assert_match('paren', "local r; local t = { x = 1 }; match 1 { (t.x) => { r = 'paren' } }; return r")
  assert_match('arrow', "local r; local f = g -> g(1); match 2 { f(x -> x + 1) => { r = 'arrow' } }; return r")
  assert_match('name', "local r; local a = 1; match 1 { a => { r = 'name' } }; return r")
  assert_match('paren', "local r; local x = 2; match (x) { 2 => { r = 'paren' } }; return r")
  assert_match('neg', "local r; local x = 2; match -x { -2 => { r = 'neg' } }; return r")
  assert_match('len', "local r; match #'ab' { 2 => { r = 'len' } }; return r")
end)

spec('match bitwise or pattern #5.3+', function()
  assert_match('bor', "local r; match 3 { (1 | 2) => { r = 'bor' } }; return r")
end)

spec('match is still a name #5.1+', function()
  assert_match('1', "return ('a1'):match('%d')")
  assert_match('2', "return string.match('b2', '%d')")
  assert_match(3, 'local t = { match = 3 }; return t.match')
  assert_match(5, 'local match = 1; match = 4; match += 1; return match')
  assert_match(2, 'local match, y = 1, 2; match, y = y, match; return match')
  assert_match(7, 'local r; local function match(x) { r = x } match(6); match (7); return r')
  assert_match(9, "local match = { x = 0 }; match.x = 8; match['x'] += 1; return match.x")
  assert_match(10, 'local match = { v = 10, get = self -> self.v }; match:get(); return match:get()')
end)

spec('match xor assignment #5.3+', function()
  assert_match(10, 'local match = 11; match ~= 1; return match')
end)

spec('match syntax errors #5.1+', function()
  assert.has_error(function() compile('match x {\n  1 => {', options) end)
  assert.has_error(function() compile('match x {', options) end)
  assert.has_error(function() compile('match x { 1 { } }', options) end)
  assert.has_error(function() compile('match x { _ => {} 1 => {} }', options) end)
end)

spec('match disabled by default #5.1+', function()
  assert_run(2, 'local match = x -> x + 1; return match(1)')
  assert.has_error(function() compile('match x { 1 => {} }') end)
end)
