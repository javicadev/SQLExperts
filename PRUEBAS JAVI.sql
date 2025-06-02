   SET SERVEROUTPUT ON;

declare
   v_total number;
begin
   v_total := f_num_categorias_cuenta(1);  -- Reemplace 1 por el ID de cuenta que desee probar
   dbms_output.put_line('Número de categorías de la cuenta 1: ' || v_total);
exception
   when others then
      dbms_output.put_line('Error: ' || sqlerrm);
end;
/

   SET SERVEROUTPUT ON;

declare
   v_plan plan%rowtype;
begin
   v_plan := f_obtener_plan_cuenta(1);  -- Reemplace 1 por un ID válido
   dbms_output.put_line('ID del plan: ' || v_plan.id);
   dbms_output.put_line('Nombre del plan: ' || v_plan.nombre);
   dbms_output.put_line('Productos permitidos: ' || v_plan.productos);
   dbms_output.put_line('Almacenamiento (MB): ' || v_plan.almacenamiento);
exception
   when others then
      dbms_output.put_line('Error: ' || sqlerrm);
end;
/

   SET SERVEROUTPUT ON;

declare
   v_total number;
begin
   v_total := f_contar_productos_cuenta(1);  -- Use un ID de cuenta válido
   dbms_output.put_line('Número de productos en la cuenta 1: ' || v_total);
exception
   when others then
      dbms_output.put_line('Error: ' || sqlerrm);
end;
/