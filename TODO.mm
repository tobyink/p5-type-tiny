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
<node CREATED="1365529877901" ID="ID_1445114250" MODIFIED="1365529919532" TEXT="link to FreeMind-Document as an example of a distribution using Type-Tiny directly (no OO framework)"/>
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
<node CREATED="1365529954377" ID="ID_1288968569" MODIFIED="1365529957564" POSITION="right" TEXT="coercion">
<node CREATED="1365442049043" ID="ID_1920269603" MODIFIED="1365529829535" TEXT="Auto-coercion">
<font NAME="SansSerif" SIZE="12"/>
<icon BUILTIN="full-3"/>
<node CREATED="1365529838164" ID="ID_1740996713" MODIFIED="1365529843768" TEXT="could do with better tests"/>
<node CREATED="1365529844572" ID="ID_700685078" MODIFIED="1365529849044" TEXT="needs documenting"/>
<node CREATED="1365529851374" ID="ID_1411816545" MODIFIED="1365529863215" TEXT="needs merge with tip"/>
<node CREATED="1365530075403" ID="ID_545406096" MODIFIED="1365530115590" TEXT="need a way of switching this feature on/off?"/>
<node CREATED="1365530123214" ID="ID_492312961" MODIFIED="1365530179212" TEXT="generated coercion functions could maybe be returned as thunks?"/>
</node>
<node CREATED="1365529965179" ID="ID_1417745941" MODIFIED="1365530069787" TEXT="investigate to what extent child types should inherit coercions"/>
</node>
</node>
</map>
