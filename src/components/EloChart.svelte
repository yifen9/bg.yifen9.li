<script>
  export let points = [];
  let w = 800, h = 320, pad = 32;
  const xs = points.map((p) => new Date(p.date).getTime());
  const ys = points.map((p) => p.rating);
  const minx = Math.min(...xs), maxx = Math.max(...xs);
  const miny = Math.min(...ys), maxy = Math.max(...ys);
  function X(t){ return pad + (w-2*pad) * ((new Date(t).getTime()-minx)/(maxx-minx||1)); }
  function Y(v){ return h - pad - (h-2*pad) * ((v-miny)/((maxy-miny)||1)); }
  const pathD = points.map((p,i)=> `${i===0?"M":"L"}${X(p.date)},${Y(p.rating)}`).join(" ");
</script>

<svg {w} {h} viewBox={`0 0 ${w} ${h}`} style="max-width:100%">
  <path d={pathD} fill="none" stroke="currentColor" stroke-width="2" />
  {#each points as p}
    <a href={`/sessions/${p.session_id}`}>
      <circle cx={X(p.date)} cy={Y(p.rating)} r="3" />
      <title>{p.date} • {p.rating}</title>
    </a>
  {/each}
</svg>
