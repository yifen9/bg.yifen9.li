<script>
  import { onMount } from "svelte";

  export let points = [];

  let range = "all";
  let width = 800;
  let height = 360;
  let pad = 40;

  let container;
  let ro;

  onMount(() => {
    if (typeof window !== "undefined" && typeof ResizeObserver !== "undefined" && container) {
      ro = new ResizeObserver((entries) => {
        for (const e of entries) {
          width = Math.max(320, e.contentRect.width);
        }
      });
      ro.observe(container);
      return () => ro && ro.disconnect();
    }
  });

  function parseDate(d) { return new Date(d); }
  function daysAgo(n) { const dt = new Date(); dt.setDate(dt.getDate() - n); return dt; }
  function inRange(p) { if (range === "all") return true; return parseDate(p.date) >= daysAgo(Number(range)); }

  $: filtered = points.filter(inRange).sort((a,b)=>+parseDate(a.date)-+parseDate(b.date));
  $: xs = filtered.map((p)=>+parseDate(p.date));
  $: ys = filtered.map((p)=>+p.rating);
  $: xMin = xs.length ? Math.min(...xs) : +new Date();
  $: xMax = xs.length ? Math.max(...xs) : +new Date();
  $: yMin = ys.length ? Math.min(...ys) : 1400;
  $: yMax = ys.length ? Math.max(...ys) : 1600;

  function X(t){ const w=width-2*pad; const d=xMax-xMin||1; return pad + (w*(t-xMin))/d; }
  function Y(v){ const h=height-2*pad; const d=yMax-yMin||1; return height - pad - (h*(v-yMin))/d; }

  $: pathD = filtered.map((p,i)=>`${i===0?"M":"L"}${X(+parseDate(p.date))},${Y(+p.rating)}`).join(" ");

  function fmtDate(d){ const dt=parseDate(d); const y=dt.getFullYear(), m=String(dt.getMonth()+1).padStart(2,"0"), dd=String(dt.getDate()).padStart(2,"0"); return `${y}-${m}-${dd}`; }
  function nearest(mx){ if(!filtered.length) return null; let best=null, dist=1/0; for(const p of filtered){ const dx=Math.abs(X(+parseDate(p.date))-mx); if(dx<dist){best=p; dist=dx;} } return best; }

  let hover = null; let mouseX = 0;
  function onMove(e){ const r=e.currentTarget.getBoundingClientRect(); mouseX = e.clientX - r.left; hover = nearest(mouseX); }
  function onLeave(){ hover = null; }
  function onClick(){ if(hover?.session_id) location.href = `/sessions/${hover.session_id}`; }
  function yt(){ const k=5, s=yMax-yMin||1, step=s/k, a=[]; for(let i=0;i<=k;i++) a.push(yMin+i*step); return a; }
  function xt(){ const k=6, s=xMax-xMin||1, step=s/k, a=[]; for(let i=0;i<=k;i++) a.push(xMin+i*step); return a; }

  function onRange(e){ range = e.currentTarget.value; }
</script>


<div bind:this={container} style="width:100%">
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
    width={width}
    height={height}
    viewBox={`0 0 ${width} ${height}`}
    on:mousemove={onMove}
    on:mouseleave={onLeave}
    on:click={onClick}
    style="touch-action:none;user-select:none;max-width:100%"
  >
    <rect x="0" y="0" width={width} height={height} fill="transparent" />

    {#each yt() as v}
      <line x1={pad} x2={width-pad} y1={Y(v)} y2={Y(v)} stroke="currentColor" opacity="0.1" />
      <text x={pad-6} y={Y(v)} text-anchor="end" dominant-baseline="middle" font-size="10">{Math.round(v)}</text>
    {/each}

    {#each xt() as t}
      <line x1={X(t)} x2={X(t)} y1={pad} y2={height-pad} stroke="currentColor" opacity="0.06" />
      <text x={X(t)} y={height-pad+14} text-anchor="middle" font-size="10">{fmtDate(new Date(t))}</text>
    {/each}

    <rect x={pad} y={pad} width={width-2*pad} height={height-2*pad} fill="none" stroke="currentColor" opacity="0.3" />

    {#if filtered.length}
      <path d={pathD} fill="none" stroke="currentColor" stroke-width="2" />
      {#each filtered as p}
        <a href={`/sessions/${p.session_id}`}>
          <circle cx={X(+parseDate(p.date))} cy={Y(+p.rating)} r="3" />
        </a>
      {/each}
    {/if}

    {#if hover}
      <line x1={X(+parseDate(hover.date))} x2={X(+parseDate(hover.date))} y1={pad} y2={height-pad} stroke="currentColor" opacity="0.3" />
      <circle cx={X(+parseDate(hover.date))} cy={Y(+hover.rating)} r="5" fill="white" stroke="currentColor" />
      <g transform={`translate(${Math.min(width-pad-160, Math.max(pad, X(+parseDate(hover.date))+8))}, ${pad+8})`}>
        <rect width="160" height="56" rx="6" ry="6" fill="white" opacity="0.95" stroke="currentColor" />
        <text x="8" y="18" font-size="12">Date: {fmtDate(hover.date)}</text>
        <text x="8" y="34" font-size="12">Rating: {hover.rating}</text>
        <text x="8" y="50" font-size="12">Games Played: {hover.games_played}</text>
      </g>
    {/if}
  </svg>
</div>
