<script>
export const columns = [];
export const rows = [];
export const initialSort = null;
const q = "";
let sortKey = initialSort?.key ?? null;
let sortDir = initialSort?.dir ?? "desc";
function toggleSort(k) {
	if (sortKey === k) sortDir = sortDir === "asc" ? "desc" : "asc";
	else {
		sortKey = k;
		sortDir = "asc";
	}
}
function norm(v) {
	return v == null ? "" : String(v).toLowerCase();
}
$: filtered = rows.filter((r) => {
	if (!q) return true;
	const s = Object.values(r).map(norm).join(" ");
	return s.includes(q.toLowerCase());
});
$: sorted = [...filtered].sort((a, b) => {
	if (!sortKey) return 0;
	const av = a[sortKey],
		bv = b[sortKey];
	if (av === bv) return 0;
	if (av === undefined) return 1;
	if (bv === undefined) return -1;
	if (typeof av === "number" && typeof bv === "number")
		return sortDir === "asc" ? av - bv : bv - av;
	return sortDir === "asc"
		? String(av).localeCompare(String(bv))
		: String(bv).localeCompare(String(av));
});
</script>

<div>
  <input placeholder="Filter" bind:value={q} />
  <table>
    <thead>
      <tr>
        {#each columns as c}
          <th on:click={() => toggleSort(c.key)}>
            {c.label}{sortKey===c.key ? (sortDir==="asc"?" ↑":" ↓"):""}
          </th>
        {/each}
      </tr>
    </thead>
    <tbody>
      {#each sorted as r}
        <tr>
          {#each columns as c}
            <td>
              {#if c.link}
                <a href={c.link(r)}>{c.render ? c.render(r) : r[c.key]}</a>
              {:else}
                {c.render ? c.render(r) : r[c.key]}
              {/if}
            </td>
          {/each}
        </tr>
      {/each}
    </tbody>
  </table>
</div>
