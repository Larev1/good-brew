const MENU = [
  {id:"americano", name:"Iced Americano", desc:"Bold, clean, dan menyegarkan.", price:10000, tag:"CLASSIC", tone:"coffee"},
  {id:"cafe-latte", name:"Iced Cafe Latte", desc:"Espresso dengan susu yang lembut.", price:13000, tag:"MILKY", tone:"latte"},
  {id:"palm-sugar-latte", name:"Iced Palm Sugar Latte", desc:"Kopi susu dengan sentuhan gula aren.", price:15000, tag:"SIGNATURE", tone:"aren"},
  {id:"oat-latte", name:"Iced Oat Latte", desc:"Latte creamy dengan oat milk.", price:16000, tag:"OAT", tone:"oat"},
  {id:"palm-sugar-oat-latte", name:"Iced Palm Sugar Oat Latte", desc:"Oat latte dengan gula aren.", price:18000, tag:"PREMIUM", tone:"oat-aren"}
];
const EXTRA_SHOT_PRICE = 3000;
const cart = {};
const rupiah = n => new Intl.NumberFormat("id-ID",{style:"currency",currency:"IDR",maximumFractionDigits:0}).format(n);
const config = window.GOOD_BREW_CONFIG || {};
const ready = config.SUPABASE_URL && config.SUPABASE_ANON_KEY &&
  !config.SUPABASE_URL.includes("PASTE_") && !config.SUPABASE_ANON_KEY.includes("PASTE_");
const db = ready && window.supabase ? window.supabase.createClient(config.SUPABASE_URL, config.SUPABASE_ANON_KEY) : null;

function renderMenu(){
  document.getElementById("menu-grid").innerHTML = MENU.map(p=>`
    <article class="menu-card">
      <div class="drink-art ${p.tone}"><span class="cup-lid"></span><span class="cup-body"><i></i></span><b>GOOD<br>BREW</b></div>
      <div class="menu-info"><span class="tag">${p.tag}</span><h3>${p.name}</h3><p>${p.desc}</p>
      <div class="menu-bottom"><strong>${rupiah(p.price)}</strong><button class="add-btn" data-add="${p.id}" aria-label="Tambah ${p.name}">+</button></div>
      <label class="extra-choice"><input type="checkbox" data-extra="${p.id}"> Extra Shot (+${rupiah(EXTRA_SHOT_PRICE)})</label></div>
    </article>`).join("");
  document.getElementById("menu-count").textContent = `${MENU.length} MENU`;
}
function renderCart(){
  const el = document.getElementById("cart-items");
  const rows = Object.entries(cart).filter(([,v])=>v.qty>0);
  if(!rows.length){el.innerHTML='<p class="muted">Keranjang masih kosong.</p>';document.getElementById("cart-total").textContent=rupiah(0);return;}
  let total=0;
  el.innerHTML=rows.map(([id,v])=>{
    const p=MENU.find(x=>x.id===id); const unit=p.price+(v.extra?EXTRA_SHOT_PRICE:0); const line=unit*v.qty; total+=line;
    return `<div class="cart-row"><div><strong>${p.name}</strong><small>${v.extra?"Extra shot · ":""}${rupiah(unit)} / cup</small></div><div class="qty"><button type="button" data-minus="${id}">−</button><b>${v.qty}</b><button type="button" data-plus="${id}">+</button></div><strong>${rupiah(line)}</strong></div>`;
  }).join("");
  document.getElementById("cart-total").textContent=rupiah(total);
}
document.addEventListener("click",e=>{
  const add=e.target.closest("[data-add]"); const plus=e.target.closest("[data-plus]"); const minus=e.target.closest("[data-minus]");
  if(add){const id=add.dataset.add;cart[id]??={qty:0,extra:false};cart[id].qty++;renderCart();}
  if(plus){cart[plus.dataset.plus].qty++;renderCart();}
  if(minus){const id=minus.dataset.minus;cart[id].qty--;if(cart[id].qty<=0)delete cart[id];renderCart();}
});
document.addEventListener("change",e=>{
  if(e.target.matches("[data-extra]")){const id=e.target.dataset.extra;cart[id]??={qty:0,extra:false};cart[id].extra=e.target.checked;renderCart();}
});
function setMinDate(){
  const d=new Date();d.setDate(d.getDate()+1);
  const local=new Date(d.getTime()-d.getTimezoneOffset()*60000).toISOString().slice(0,10);
  const input=document.getElementById("pickup-date");input.min=local;input.value=local;
}
document.querySelectorAll('input[name="fulfillment"]').forEach(r=>r.addEventListener("change",()=>{
  document.getElementById("delivery-hint").textContent = r.checked && r.value==="delivery" ? "Alamat delivery dikunci ke Maximart Yanglim. Ongkir Rp0." : "Delivery hanya ke Maximart Yanglim dan gratis.";
}));
document.getElementById("checkout-form").addEventListener("submit",async e=>{
  e.preventDefault();
  const form = e.currentTarget;
  const msg=document.getElementById("checkout-message"), btn=document.getElementById("submit-order");
  const entries=Object.entries(cart).filter(([,v])=>v.qty>0);
  if(!entries.length){msg.textContent="Tambahkan minimal satu menu ke keranjang.";return;}
  if(!db){msg.textContent="Aplikasi belum terhubung ke database. Lengkapi konfigurasi Supabase terlebih dahulu.";return;}
  const fd=new FormData(form);
  const items=entries.map(([id,v])=>({product_id:id,quantity:v.qty,extra_shot:v.extra}));
  btn.disabled=true;btn.textContent="Mengirim...";
  try{
    const {data,error}=await db.rpc("place_good_brew_order",{
      p_customer_name:String(fd.get("customer_name")).trim(),
      p_whatsapp:String(fd.get("whatsapp")).trim(),
      p_fulfillment:fd.get("fulfillment"),
      p_destination:fd.get("fulfillment")==="delivery"?"Maximart Yanglim":"Pickup",
      p_ready_date:fd.get("pickup_date"),
      p_ready_time:fd.get("pickup_time"),
      p_notes:String(fd.get("notes")||"").trim(),
      p_items:items
    });
    if(error) throw error;
    const id=data;
    msg.innerHTML=`Pesanan berhasil dikirim. Nomor pesanan: <strong>${id}</strong>. Status pembayaran: menunggu konfirmasi admin. Simpan nomor pesanan ini.`;

Object.keys(cart).forEach(k=>delete cart[k]);
renderCart();

const checkoutForm = document.getElementById("checkout-form");
if (checkoutForm) {
  checkoutForm.reset();
}

setMinDate();
  }catch(err){msg.textContent="Pesanan belum terkirim: "+(err.message||"Terjadi kesalahan.");}
  finally{btn.disabled=false;btn.textContent="Kirim pesanan";}
});
renderMenu();renderCart();setMinDate();
