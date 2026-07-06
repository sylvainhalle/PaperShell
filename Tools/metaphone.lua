--[[
    PaperShell, a flexible LaTeX environment for scientific papers
    Copyright (C) 2015-2026  Sylvain Hallé

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]

--[[ The replacements used to calculate the metaphone of a word. This list
     is taken from GNU Aspell's implementation of the algorithm:
     http://aspell.net/metaphone/english_phonet.dat.
--]]
REPLACEMENTS = {
{"AH(AEIOUY)-^", "*H"},
{"AR(AEIOUY)-^", "*R"},
{"A(HR)^", "*"},
{"A^", "*"},
{"AH(AEIOUY)-", "H"},
{"AR(AEIOUY)-", "R"},
{"A(HR)", "_"},
{"BB-", "_"},
{"B", "B"},
{"CQ-", "_"},
{"CIA", "X"},
{"CH", "X"},
{"C(EIY)-", "S"},
{"CK", "K"},
{"COUGH^", "KF"},
{"CC<", "C"},
{"C", "K"},
{"DG(EIY)", "K"},
{"DD-", "_"},
{"D", "T"},
{"É<", "E"},
{"EH(AEIOUY)-^", "*H"},
{"ER(AEIOUY)-^", "*R"},
{"E(HR)^", "*"},
{"ENOUGH^$", "*NF"},
{"E^", "*"},
{"EH(AEIOUY)-", "H"},
{"ER(AEIOUY)-", "R"},
{"E(HR)", "_"},
{"FF-", "_"},
{"F", "F"},
{"GN^", "N"},
{"GN$", "N"},
{"GNS$", "NS"},
{"GNED$", "N"},
{"GH(AEIOUY)-", "K"},
{"GH", "_"},
{"GG9", "K"},
{"G", "K"},
{"H", "H"},
{"IH(AEIOUY)-^", "*H"},
{"IR(AEIOUY)-^", "*R"},
{"I(HR)^", "*"},
{"I^", "*"},
{"ING6", "N"},
{"IH(AEIOUY)-", "H"},
{"IR(AEIOUY)-", "R"},
{"I(HR)", "_"},
{"J", "K"},
{"KN^", "N"},
{"KK-", "_"},
{"K", "K"},
{"LAUGH^", "LF"},
{"LL-", "_"},
{"L", "L"},
{"MB$", "M"},
{"MM", "M"},
{"M", "M"},
{"NN-", "_"},
{"N", "N"},
{"OH(AEIOUY)-^", "*H"},
{"OR(AEIOUY)-^", "*R"},
{"O(HR)^", "*"},
{"O^", "*"},
{"OH(AEIOUY)-", "H"},
{"OR(AEIOUY)-", "R"},
{"O(HR)", "_"},
{"PH", "F"},
{"PN^", "N"},
{"PP-", "_"},
{"P", "P"},
{"Q", "K"},
{"RH^", "R"},
{"ROUGH^", "RF"},
{"RR-", "_"},
{"R", "R"},
{"SCH(EOU)-", "SK"},
{"SC(IEY)-", "S"},
{"SH", "X"},
{"SI(AO)-", "X"},
{"SS-", "_"},
{"S", "S"},
{"TI(AO)-", "X"},
{"TH", "@"},
{"TCH--", "_"},
{"TOUGH^", "TF"},
{"TT-", "_"},
{"T", "T"},
{"UH(AEIOUY)-^", "*H"},
{"UR(AEIOUY)-^", "*R"},
{"U(HR)^", "*"},
{"U^", "*"},
{"UH(AEIOUY)-", "H"},
{"UR(AEIOUY)-", "R"},
{"U(HR)", "_"},
{"V^", "W"},
{"V", "F"},
{"WR^", "R"},
{"WH^", "W"},
{"W(AEIOU)-", "W"},
{"X^", "S"},
{"X", "KS"},
{"Y(AEIOU)-", "Y"},
{"ZZ-", "_"},
{"Z", "S"}
}

function metaphone(word)
  for _, rule in ipairs(REPLACEMENTS) do
    local from, to = rule[1], rule[2]
    word = word:gsub(from, to)
    print(word)
  end
  return word
end

return {
	metaphone = metaphone
}

-- :folding=explicit:wrap=none:mode=lua: