<script>
export let columns = [];
export let rows = [];
export let initialSort = null;
export let rowLink = null;

let q = "";
let sortKey = initialSort?.key ?? null;
let sortDir = initialSort?.dir ?? "desc";

function setQuery(e) {
	q = e.currentTarget.value;
}
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

function buildHref(spec, row) {
	if (!spec) return null;
	const key = spec.key ?? spec.hrefKey ?? spec.field ?? spec.for;
	const has = key && key in row;
	if (!has) return null;
	const v = row[key];
	const enc = spec.encode !== false;
	const val = enc ? encodeURIComponent(String(v)) : String(v);
	const pre = spec.prefix ?? "";
	const suf = spec.suffix ?? "";
	return `${pre}${val}${suf}`;
}

function go(row) {
	const h = buildHref(rowLink, row);
	if (h) {
		if (typeof window !== "undefined") window.location.href = h;
	}
}

function displayValue(c, row) {
	const v = row[c.key];
	if (Array.isArray(v) && typeof c.join === "string") return v.join(c.join);
	return v;
}

$: safeRows = Array.isArray(rows) ? rows : [];
$: filtered = safeRows.filter((r) => {
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
  <input type="search" placeholder="Filter" value={q} on:input={setQuery} />
  <div>Rows: {safeRows.length}</div>
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
        <tr on:click={() => go(r)} style="cursor: {rowLink ? 'pointer' : 'default'}">
          {#each columns as c}
            <td>
              {#if c.link && buildHref(c.link, r)}
                <a href={buildHref(c.link, r)}>{displayValue(c, r)}</a>
              {:else}
                {displayValue(c, r)}
              {/if}
            </td>
          {/each}
        </tr>
      {/each}
    </tbody>
  </table>
</div>
