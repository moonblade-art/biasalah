-- Function to process a successful donation securely
create or replace function process_successful_donation(
  p_donation_id uuid,
  p_transaction_id text
)
returns void
language plpgsql
security definer -- Runs with permissions of the creator (admin), bypassing RLS for the update
as $$
declare
  v_donation_amount numeric;
  v_carbon_amount numeric;
  v_user_id uuid;
  v_current_status text;
begin
  -- 1. Get donation details and lock the row to prevent race conditions
  select amount, carbon_amount, user_id, payment_status
  into v_donation_amount, v_carbon_amount, v_user_id, v_current_status
  from donations
  where id = p_donation_id
  for update;

  if not found then
    raise exception 'Donation not found';
  end if;

  -- 2. Idempotency Check: If already success, do nothing
  if v_current_status = 'success' then
    return;
  end if;

  -- 3. Update Donation Status
  update donations
  set 
    payment_status = 'success',
    midtrans_transaction_id = p_transaction_id,
    paid_at = now()
  where id = p_donation_id;

  -- 4. Update User Profile (Atomic Increment/Decrement)
  -- Decrease emisi_belum (un-offset emissions)
  -- Increase emisi_offset (total offset emissions)
  update users
  set 
    emisi_belum = greatest(0, emisi_belum - v_carbon_amount),
    emisi_offset = emisi_offset + v_carbon_amount
  where user_id = v_user_id;

  -- Optional: Log activity or create notification here if needed

exception
  when others then
    raise exception 'Failed to process donation: %', sqlerrm;
end;
$$;
