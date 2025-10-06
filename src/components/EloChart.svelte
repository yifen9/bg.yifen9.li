<script>
  import { onMount } from "svelte";

  export let points = [];

  let range = "all";
  const vw = 1000;
  const vh = 360;
  let pad = 40;

  let svgEl;

  const toTime = (d) => d instanceof Date ? d.getTime() : (typeof d === "number" ? d : new Date(d).getTime());
  const toDate = (d) => d instanceof Date ? d : new Date(d);

  function daysAgo(n) {
    const dt = new Date();
    dt.setDate(dt.getDate() - n);
    return dt;
  }
  function inRange(p) {
    if (range === "all") return true;
    return toDate(p.date) >= daysAgo(Number(range));
  }

  $: filtered = points.filter(inRange).sort((a, b) => toTime(a.date) - toTime(b.date));
  $: xs = filtered.map((p) => toTime(p.date));
  $: ys = filtered.map((p) => +p.rating);

  $: xMin0 = xs.length ? Math.min(...xs) : Date.now() - 86400000;
  $: xMax0 = xs.length ? Math.max(...xs) : Date.now();
  $: yMin0 = ys.length ? Math.min(...ys) : 1400;
  $: yMax0 = ys.length ? Math.max(...ys) : 1600;

  const ONE_HOUR = 60 * 60 * 1000;
  $: xSpan = Math.max(1, xMax0 - xMin0);
  $: ySpan = Math.max(1, yMax0 - yMin0);
  $: xPad = Math.max(xSpan * 0.05, ONE_HOUR);
  $: yPad = Math.max(ySpan * 0.05, 6);

  $: xMin = xMin0 - xPad;
  $: xMax = xMax0 + xPad;
  $: yMin = yMin0 - yPad;
  $: yMax = yMax0 + yPad;

  function X(t){ const w=vw-2*pad; const d=xMax-xMin||1; return pad + (w*(t-xMin))/d; }
  function Y(v){ const h=vh-2*pad; const d=yMax-yMin||1; return vh - pad - (h*(v-yMin))/d; }

  $: pathD = filtered.map((p,i)=>`${i===0?"M":"L"}${X(toTime(p.date))},${Y(+p.rating)}`).join(" ");

  function fmtDate(d){
    const dt = toDate(d);
    if (Number.isNaN(+dt)) return "";
    const y=dt.getFullYear(), m=String(dt.getMonth()+1).padStart(2,"0"), dd=String(dt.getDate()).padStart(2,"0");
    return `${y}-${m}-${dd}`;
  }

  function svgPoint(evt){
    const pt = svgEl.createSVGPoint();
    pt.x = evt.clientX;
    pt.y = evt.clientY;
    const m = svgEl.getScreenCTM().inverse();
    const p = pt.matrixTransform(m);
    return { x: p.x, y: p.y };
  }

  function nearest(mx, my){
    if(!filtered.length) return null;
    let best=null, dist=Infinity;
    for(const p of filtered){
      const dx = X(toTime(p.date)) - mx;
      const dy = Y(+p.rating) - my;
      const d2 = dx*dx + dy*dy;
      if(d2 < dist){ best=p; dist=d2; }
    }
    return best;
  }

  let hover = null;
  function onMove(e){
    const p = svgPoint(e);
    hover = nearest(p.x, p.y);
  }
  function onLeave(){ hover = null; }
  function onClickPoint(p){ if (p?.session_id) location.href = `/sessions/${p.session_id}`; }

  function yt(){ const k=5, s=yMax-yMin||1, step=s/k, a=[]; for(let i=0;i<=k;i++) a.push(yMin+i*step); return a; }
  function xt(){ const k=6, s=xMax-xMin||1, step=s/k, a=[]; for(let i=0;i<=k;i++) a.push(xMin+i*step); return a; }
  function onRange(e){ range = e.currentTarget.value; }

  onMount(()=>{});
</script>

<div style="width:100%">
  <div style="display:flex;gap:.5rem;align-items:center;margin:.5rem 0">
    <label>Range</label>
    <select value={range} on:change={onRange}>
      <option value="all">All</option>
      <option value="30">30d</option>
      <option value="90">90d</option>
      <option value="180">180d</option>
      <option value="365">365d</option>
    </select>
  </div>

  <svg
    bind:this={svgEl}
    width="100%"
    height={vh}
    viewBox={`0 0 ${vw} ${vh}`}
    on:mousemove={onMove}
    on:mouseleave={onLeave}
    style="display:block;max-width:100%"
  >
    <rect x="0" y="0" width={vw} height={vh} fill="transparent" />

    {#each yt() as v}
      <line x1={pad} x2={vw-pad} y1={Y(v)} y2={Y(v)} stroke="currentColor" opacity="0.1" />
      <text x={pad-6} y={Y(v)} text-anchor="end" dominant-baseline="middle" font-size="10">{Math.round(v)}</text>
    {/each}

    {#each xt() as t}
      <line x1={X(t)} x2={X(t)} y1={pad} y2={vh-pad} stroke="currentColor" opacity="0.06" />
      <text x={X(t)} y={vh-pad+14} text-anchor="middle" font-size="10">{fmtDate(t)}</text>
    {/each}

    <rect x={pad} y={pad} width={vw-2*pad} height={vh-2*pad} fill="none" stroke="currentColor" opacity="0.3" />

    {#if filtered.length}
      <path d={pathD} fill="none" stroke="currentColor" stroke-width="2" />
      {#each filtered as p}
        <g
          transform={`translate(${X(toTime(p.date))},${Y(+p.rating)})`}
          on:click={() => onClickPoint(p)}
          style="cursor:pointer"
        >
          <circle r="3" />
          <circle r="10" opacity="0" />
          <title>{fmtDate(p.date)} • {(+p.rating).toFixed(2)} • Games Played: {p.games_played}</title>
        </g>
      {/each}
    {:else}
      <text x={vw/2} y={vh/2} text-anchor="middle" font-size="12">No data in range</text>
    {/if}

    {#if hover}
      <line x1={X(toTime(hover.date))} x2={X(toTime(hover.date))} y1={pad} y2={vh-pad} stroke="currentColor" opacity="0.3" />
      <circle cx={X(toTime(hover.date))} cy={Y(+hover.rating)} r="5" fill="white" stroke="currentColor" />
      <g transform={`translate(${Math.min(vw-pad-160, Math.max(pad, X(toTime(hover.date))+8))}, ${pad+8})`}>
        <rect width="160" height="56" rx="6" ry="6" fill="white" opacity="0.95" stroke="currentColor" />
        <text x="8" y="18" font-size="12">Date: {fmtDate(hover.date)}</text>
        <text x="8" y="34" font-size="12">Rating: {(+hover.rating).toFixed(2)}</text>
        <text x="8" y="50" font-size="12">Games Played: {hover.games_played}</text>
      </g>
    {/if}
  </svg>
</div>
