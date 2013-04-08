<map version="0.9.0">
<!-- To view this file, download free mind mapping software FreeMind from http://freemind.sourceforge.net -->
<node CREATED="1365159230192" ID="ID_28734446" MODIFIED="1365442318390" TEXT="Type-Tiny">
<node CREATED="1365159476220" ID="ID_326312292" MODIFIED="1365441636185" POSITION="right" TEXT="documentation">
<node CREATED="1365159650166" FOLDED="true" ID="ID_243763962" MODIFIED="1365441691037" TEXT="usage with Mouse">
<icon BUILTIN="full-5"/>
<node CREATED="1365159658261" ID="ID_537118133" MODIFIED="1365159664111" TEXT="using type constraints from libraries"/>
<node CREATED="1365159668221" ID="ID_785265846" MODIFIED="1365159675666" TEXT="creating type constraints using Type::Utils"/>
<node CREATED="1365159676662" ID="ID_1609293562" MODIFIED="1365159679179" TEXT="coercions"/>
</node>
</node>
<node CREATED="1365159705390" ID="ID_1309512802" MODIFIED="1365441700190" POSITION="left" TEXT="integration with MooX-late">
<icon BUILTIN="full-3"/>
</node>
<node CREATED="1365441709337" ID="ID_921538277" MODIFIED="1365442088103" POSITION="right" TEXT="new type constraints for Types::Standard">
<icon BUILTIN="full-3"/>
<node CREATED="1365441750514" ID="ID_411979884" MODIFIED="1365441790471" TEXT="Chars - i.e. strings where the UTF-8 bit is on"/>
<node CREATED="1365441769529" ID="ID_944847020" MODIFIED="1365441781094" TEXT="Bytes - i.e. strings where the UTF-8 bit is off"/>
<node CREATED="1365441792858" ID="ID_393588377" MODIFIED="1365441880404" TEXT="Tied - i.e. references to tied variables. Parameterized: Tied[&quot;Some::Package&quot;]"/>
<node CREATED="1365441884333" ID="ID_849860266" MODIFIED="1365441977843" TEXT="Varchar[length]"/>
<node CREATED="1365441979900" ID="ID_1969541225" MODIFIED="1365442361862" TEXT="steal from MooseX-Types-Common?"/>
<node CREATED="1365442342382" ID="ID_345593149" MODIFIED="1365442365283" TEXT="steal from MooseX-Types-Ro?"/>
</node>
<node CREATED="1365442049043" FOLDED="true" ID="ID_1920269603" MODIFIED="1365442316721" POSITION="left" TEXT="Auto-coercion">
<richcontent TYPE="NOTE"><html>
  <head>
    
  </head>
  <body>
    <p>
      e.g. if a coercion exists for Bar, then creating parameterized ArrayRef[Bar] should create coercion ArrayRef[Any]-&gt;ArrayRef[Bar]
    </p>
  </body>
</html>
</richcontent>
<font NAME="SansSerif" SIZE="12"/>
<icon BUILTIN="full-3"/>
<node CREATED="1365442300798" ID="ID_1913696701" MODIFIED="1365442304106" TEXT="ArrayRef"/>
<node CREATED="1365442305110" ID="ID_1481710724" MODIFIED="1365442307257" TEXT="HashRef"/>
<node CREATED="1365442307650" ID="ID_1249248601" MODIFIED="1365442313309" TEXT="ScalarRef"/>
</node>
</node>
</map>
