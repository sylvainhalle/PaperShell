#! /usr/bin/fish
## Packs each theme into a bundle

pushd ../Source
for t in tpl/*/
  set tplname $(path basename $t)
  set tplout ../$tplname.tpl.zip
  rm -f $tplout
  7z a -mx9 -x@../Tools/pack.exclude.txt $tplout sty/$tplname tpl/$tplname
end
popd