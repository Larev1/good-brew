const config=window.GOOD_BREW_CONFIG||{};
const ready=config.SUPABASE_URL&&config.SUPABASE_ANON_KEY&&!config.SUPABASE_URL.includes("PASTE_")&&!config.SUPABASE_ANON_KEY.includes("PASTE_");
const db=ready&&window.supabase?window.supabase.createClient(config.SUPABASE_URL,config.SUPABASE_ANON_KEY):null;
const rupiah=n=>new Intl.NumberFormat("id-ID",{style:"currency",currency:"IDR",maximumFractionDigits:0}).format(n||0);
const $=id=>document.getElementById(id);
function showLogin(message=""){ $("login-panel").hidden=false;$("dashboard").hidden=true;$("login-message").textContent=message; }
function showDash(){ $("login-panel").hidden=true;$("dashboard").hidden=false;loadOrders(); }
$("login-form").addEventListener("submit",async e=>{
  e.preventDefault();if(!db){showLogin("Supabase belum dikonfigurasi. Periksa config.js.");return;}
  const fd=new FormData(e.currentTarget);
  const {error}=await db.auth.signInWithPassword({email:fd.get("email"),password:fd.get("password")});
  if(error){showLogin(error.message);return;}
  showDash();
});
$("logout-btn").addEventListener("click",async()=>{await db.auth.signOut();showLogin("Kamu sudah keluar.");});
$("refresh-btn").addEventListener("click",loadOrders);
$("filter-date").addEventListener("change",loadOrders);
async function loadOrders(){
  if(!db)return;
  $("orders-list").innerHTML='<p class="muted">Memuat pesanan...</p>';
  let q=db.from("orders").select("*,order_items(*)").order("created_at",{ascending:false}).limit(100);
  const date=$("filter-date").value;if(date)q=q.eq("ready_date",date);
  const {data,error}=await q;
  if(error){$("orders-list").innerHTML=`<p class="error">Gagal memuat: ${error.message}</p>`;return;}
  const orders=data||[];
  $("stat-orders").textContent=orders.length;
  $("stat-revenue").textContent=rupiah(orders.reduce((s,o)=>s+(o.total||0),0));
  $("stat-pending").textContent=orders.filter(o=>o.payment_status!=="paid").length;
  if(!orders.length){$("orders-list").innerHTML='<div class="empty-state">Belum ada pesanan pada filter ini.</div>';return;}
  $("orders-list").innerHTML=orders.map(o=>{
    const items=(o.order_items||[]).map(i=>`${i.quantity} × ${i.product_name}${i.extra_shot?" (Extra Shot)":""}`).join("<br>");
    return `<article class="order-card">
      <div class="order-top"><div><span class="tag">${new Date(o.created_at).toLocaleString("id-ID")}</span><h3>${escapeHtml(o.customer_name)}</h3><p>${escapeHtml(o.whatsapp)} · ${o.fulfillment==="delivery"?"Delivery: Maximart Yanglim":"Pickup"}</p></div><strong>${rupiah(o.total)}</strong></div>
      <div class="order-details"><div><small>ITEM</small><p>${items}</p><small>JADWAL</small><p>${o.ready_date} · ${o.ready_time}</p>${o.notes?`<small>CATATAN</small><p>${escapeHtml(o.notes)}</p>`:""}</div>
      <div class="status-controls"><label>Pembayaran<select data-field="payment_status" data-id="${o.id}"><option value="pending" ${o.payment_status==="pending"?"selected":""}>Menunggu</option><option value="paid" ${o.payment_status==="paid"?"selected":""}>Dibayar</option></select></label>
      <label>Produksi<select data-field="order_status" data-id="${o.id}"><option value="new" ${o.order_status==="new"?"selected":""}>Pesanan baru</option><option value="preparing" ${o.order_status==="preparing"?"selected":""}>Diproses</option><option value="ready" ${o.order_status==="ready"?"selected":""}>Siap</option><option value="completed" ${o.order_status==="completed"?"selected":""}>Selesai</option><option value="cancelled" ${o.order_status==="cancelled"?"selected":""}>Dibatalkan</option></select></label></div></div>
    </article>`;
  }).join("");
}
function escapeHtml(s){return String(s||"").replace(/[&<>"']/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));}
document.addEventListener("change",async e=>{
  if(!e.target.matches("[data-field]"))return;
  const field=e.target.dataset.field,id=e.target.dataset.id,value=e.target.value;
  const {error}=await db.from("orders").update({[field]:value}).eq("id",id);
  if(error){alert("Gagal memperbarui: "+error.message);return;}
  loadOrders();
});
(async()=>{if(!db){showLogin("Lengkapi config.js dan jalankan SQL setup terlebih dahulu.");return;}const {data}=await db.auth.getSession();if(data.session)showDash();else showLogin();})();
