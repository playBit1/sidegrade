import QtQuick

// One password character, drawn as one of seven rounded shapes (cycled by position),
// after the "material shape" password characters of the lockscreen.
Canvas {
    id: dot
    property int kind: 0
    property color color: "#c8c6c3"
    width: 18
    height: 18
    onColorChanged: requestPaint()
    onKindChanged: requestPaint()

    function polygon(ctx, points, join) {
        ctx.lineJoin = "round";
        ctx.lineWidth = join;
        ctx.beginPath();
        for (var i = 0; i < points.length; i++) {
            if (i === 0) ctx.moveTo(points[i][0], points[i][1]);
            else ctx.lineTo(points[i][0], points[i][1]);
        }
        ctx.closePath();
        ctx.fill();
        ctx.stroke();
    }
    function ring(n, rOuter, rInner, rot) {
        var pts = [];
        var count = rInner > 0 ? n * 2 : n;
        for (var i = 0; i < count; i++) {
            var r = (rInner > 0 && i % 2) ? rInner : rOuter;
            var a = rot + i * 2 * Math.PI / count;
            pts.push([9 + r * Math.cos(a), 9 + r * Math.sin(a)]);
        }
        return pts;
    }
    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        ctx.fillStyle = dot.color;
        ctx.strokeStyle = dot.color;
        var up = -Math.PI / 2;
        switch (dot.kind % 7) {
        case 0: // four-leaf clover
            ctx.beginPath();
            [[5.6, 5.6], [12.4, 5.6], [5.6, 12.4], [12.4, 12.4]].forEach(function (p) {
                ctx.moveTo(p[0] + 4.4, p[1]);
                ctx.arc(p[0], p[1], 4.4, 0, 2 * Math.PI);
            });
            ctx.fill();
            break;
        case 1: // arrow
            polygon(ctx, [[9, 3], [15, 14.5], [9, 11.5], [3, 14.5]], 3);
            break;
        case 2: // diagonal pill
            ctx.translate(9, 9);
            ctx.rotate(-Math.PI / 4);
            ctx.beginPath();
            ctx.roundedRect(-8.5, -4.6, 17, 9.2, 4.6, 4.6);
            ctx.fill();
            break;
        case 3: // soft burst
            polygon(ctx, ring(8, 7.6, 5.6, up), 2.4);
            break;
        case 4: // diamond
            polygon(ctx, ring(4, 7.2, 0, up), 3.2);
            break;
        case 5: // clam shell
            polygon(ctx, [[3.2, 6.5], [9, 3.2], [14.8, 6.5], [14.8, 11.5], [9, 14.8], [3.2, 11.5]], 3.2);
            break;
        default: // pentagon
            polygon(ctx, ring(5, 7, 0, up), 3.4);
        }
    }
}
