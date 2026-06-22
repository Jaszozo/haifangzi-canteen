-- ============================================================
-- 海房子食堂 · Supabase 建表脚本（只需运行一次）
-- 用法：Supabase 控制台 → 左侧 SQL Editor → New query → 粘贴下面全部 → Run
-- ============================================================

-- 1) 菜谱表（每道菜一行；ing 是食材数组）
create table if not exists dishes (
  id   bigint generated always as identity primary key,
  cat  text not null check (cat in ('A','B','C')),
  name text not null,
  ing  jsonb not null default '[]'::jsonb,
  unique (cat, name)
);

-- 2) 市价表（key = 食材|单位，如 猪腿肉|斤）
create table if not exists prices (
  key   text primary key,
  price numeric not null
);

-- 3) 全局状态（单行：人数 + 今日确认的三菜）
create table if not exists app_state (
  id     int primary key default 1,
  people int not null default 10,
  pick   jsonb,
  constraint single_row check (id = 1)
);
insert into app_state (id, people) values (1, 10) on conflict (id) do nothing;

-- 4) 开启行级安全，并允许“公开 key（匿名）”读写（内部工具、无登录）
alter table dishes    enable row level security;
alter table prices    enable row level security;
alter table app_state enable row level security;

drop policy if exists "public_all_dishes" on dishes;
drop policy if exists "public_all_prices" on prices;
drop policy if exists "public_all_state"  on app_state;
create policy "public_all_dishes" on dishes    for all using (true) with check (true);
create policy "public_all_prices" on prices    for all using (true) with check (true);
create policy "public_all_state"  on app_state for all using (true) with check (true);

-- 5) 开启实时同步（某人改动 → 所有人页面自动更新）
do $$
begin
  begin alter publication supabase_realtime add table dishes;    exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table prices;    exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table app_state; exception when duplicate_object then null; end;
end $$;

-- 完成。回到网页点“🌱 载入默认菜谱”即可灌入初始菜单。

-- 后续新增：买菜清单的“无需购买/要买”当天勾选
alter table app_state add column if not exists pantry jsonb not null default '[]'::jsonb;
