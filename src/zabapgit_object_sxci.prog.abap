*&---------------------------------------------------------------------*
*& Include zabapgit_object_sxci
*&---------------------------------------------------------------------*

CLASS lcl_object_sxci DEFINITION INHERITING FROM lcl_objects_super FINAL.

  PUBLIC SECTION.
    INTERFACES lif_object.
  PRIVATE SECTION.
    CONSTANTS: BEGIN OF co_badi_comp_name,
                 filters            TYPE string VALUE 'FILTERS',
                 function_codes     TYPE string VALUE 'FUNCTION_CODES',
                 control_composites TYPE string VALUE 'CONTROL_COMPOSITES',
                 customer_includes  TYPE string VALUE 'CUSTOMER_INCLUDES',
                 screens            TYPE string VALUE 'SCREENS',
               END OF co_badi_comp_name.

ENDCLASS.

CLASS lcl_object_sxci IMPLEMENTATION.

  METHOD lif_object~has_changed_since.

    rv_changed = abap_true.

  ENDMETHOD.

  METHOD lif_object~changed_by.

    rv_user = c_user_unknown.

  ENDMETHOD.

  METHOD lif_object~get_metadata.

    rs_metadata = get_metadata( ).

  ENDMETHOD.

  METHOD lif_object~exists.

    DATA: lv_imp_name TYPE rsexscrn-imp_name.

    CALL FUNCTION 'SXV_IMP_EXISTS'
      EXPORTING
        imp_name           = lv_imp_name
      EXCEPTIONS
        not_existing       = 1
        data_inconsistency = 2
        OTHERS             = 3.

    rv_bool = boolc( sy-subrc = 0 ).

  ENDMETHOD.

  METHOD lif_object~serialize.

    DATA: lv_imp_name           TYPE rsexscrn-imp_name,
          lv_exit_name          TYPE rsexscrn-exit_name,
          lo_filter_obj         TYPE REF TO cl_badi_flt_struct,
          lv_ext_clname         TYPE seoclsname,
          ls_badi               TYPE badi_data,
          ls_impl               TYPE impl_data,
          lv_mast_langu         TYPE sy-langu,
          lo_filter_values_obj  TYPE REF TO cl_badi_flt_values_alv,
          lt_function_codes     TYPE seex_fcode_table,
          lt_control_composites TYPE seex_coco_table,
          lt_customer_includes  TYPE seex_table_table,
          lt_screens            TYPE seex_screen_table,
          lt_filters            TYPE seex_filter_table.

    lv_imp_name = ms_item-obj_name.

    CALL FUNCTION 'SXV_EXIT_FOR_IMP'
      EXPORTING
        imp_name           = lv_imp_name
      IMPORTING
        exit_name          = lv_exit_name
      TABLES
        filters            = lt_filters
      EXCEPTIONS
        data_inconsistency = 1
        OTHERS             = 2.

    IF sy-subrc <> 0.
      zcx_abapgit_exception=>raise( 'error from SXV_EXIT_FOR_IMP' ).
    ENDIF.

    CALL FUNCTION 'SXO_BADI_READ'
      EXPORTING
        exit_name    = lv_exit_name    " Enhancement Name
      IMPORTING
        badi         = ls_badi
        ext_clname   = lv_ext_clname    " Object Type Name
        filter_obj   = lo_filter_obj
      EXCEPTIONS
        read_failure = 1
        OTHERS       = 2.

    IF sy-subrc <> 0.
      zcx_abapgit_exception=>raise( 'error from SXV_EXIT_FOR_IMP' ).
    ENDIF.

    CALL FUNCTION 'SXO_IMPL_FOR_BADI_READ'
      EXPORTING
        imp_name          = lv_imp_name     " Implementation name for an enhancement
        exit_name         = lv_exit_name    " Enhancement Name
        inter_name        = ls_badi-inter_name     " Interface Name
        filter_obj        = lo_filter_obj    " Manage Filter Type Structures for Business Add-Ins
      IMPORTING
        impl              = ls_impl
        mast_langu        = lv_mast_langu
        filter_values_obj = lo_filter_values_obj    " Manage Filter Values in ALV Grid for Business Add-Ins
      TABLES
        fcodes            = lt_function_codes
        cocos             = lt_control_composites
        intas             = lt_customer_includes
        scrns             = lt_screens
      EXCEPTIONS
        read_failure      = 1
        OTHERS            = 2.

    IF sy-subrc <> 0.
      zcx_abapgit_exception=>raise( 'error from SXV_EXIT_FOR_IMP' ).
    ENDIF.

    CLEAR: ls_impl-aname,
           ls_impl-adate,
           ls_impl-atime,
           ls_impl-uname,
           ls_impl-udate,
           ls_impl-utime.

    io_xml->add( iv_name = 'SXCI'
                 ig_data = ls_impl ).

    io_xml->add( iv_name = co_badi_comp_name-filters
                 ig_data = lt_filters ).

    io_xml->add( iv_name = co_badi_comp_name-function_codes
                 ig_data = lt_function_codes ).

    io_xml->add( iv_name = co_badi_comp_name-control_composites
                 ig_data = lt_control_composites ).

    io_xml->add( iv_name = co_badi_comp_name-customer_includes
                 ig_data = lt_customer_includes ).

    io_xml->add( iv_name = co_badi_comp_name-screens
                 ig_data = lt_screens ).

  ENDMETHOD.

  METHOD lif_object~deserialize.

    DATA: ls_impl               TYPE impl_data,
          lt_filters            TYPE seex_filter_table,
          lt_function_codes     TYPE seex_fcode_table,
          lt_control_composites TYPE seex_coco_table,
          lt_customer_includes  TYPE seex_table_table,
          lt_screens            TYPE seex_screen_table,
          ls_badi               TYPE badi_data,
          lv_ext_clname         TYPE seoclsname,
          lo_filter_obj         TYPE REF TO cl_badi_flt_struct,
          lo_filter_val_obj     TYPE REF TO cl_badi_flt_values_alv,
          lv_korrnum            TYPE trkorr,
          flt_ext               TYPE rsexscrn-flt_ext,
          lv_package            TYPE devclass.

    io_xml->read(
      EXPORTING
        iv_name = 'SXCI'
      CHANGING
        cg_data = ls_impl ).

    io_xml->read(
      EXPORTING
        iv_name = co_badi_comp_name-filters
      CHANGING
        cg_data = lt_filters ).

    io_xml->read(
      EXPORTING
        iv_name = co_badi_comp_name-function_codes
      CHANGING
        cg_data = lt_function_codes ).

    io_xml->read(
      EXPORTING
        iv_name = co_badi_comp_name-control_composites
      CHANGING
        cg_data = lt_control_composites ).

    io_xml->read(
      EXPORTING
        iv_name = co_badi_comp_name-customer_includes
      CHANGING
        cg_data = lt_customer_includes ).

    io_xml->read(
      EXPORTING
        iv_name = co_badi_comp_name-screens
      CHANGING
        cg_data = lt_screens ).

    CALL FUNCTION 'SXO_BADI_READ'
      EXPORTING
        exit_name    = ls_impl-exit_name    " Enhancement Name
      IMPORTING
        badi         = ls_badi
        ext_clname   = lv_ext_clname    " Object Type Name
        filter_obj   = lo_filter_obj
      EXCEPTIONS
        read_failure = 1
        OTHERS       = 2.

    IF sy-subrc <> 0.
      zcx_abapgit_exception=>raise( 'error from SXO_BADI_READ' ).
    ENDIF.

    lv_package = iv_package.

    CREATE OBJECT lo_filter_val_obj
      EXPORTING
        filter_object = lo_filter_obj    " Manage Filter Type Structures for Business Add-Ins
        filter_values = lt_filters.    " Filter Values

    CALL FUNCTION 'SXO_IMPL_SAVE'
      EXPORTING
        impl             = ls_impl
        flt_ext          = flt_ext    " Alternative
        filter_val_obj   = lo_filter_val_obj    " Manage Filter Values in ALV Grid for Business Add-Ins
        genflag          = abap_true     " Generation Flag
        no_dialog        = abap_true     " No dialogs
      TABLES
        fcodes_to_insert = lt_function_codes
        cocos_to_insert  = lt_control_composites
        intas_to_insert  = lt_customer_includes
        sscrs_to_insert  = lt_screens
      CHANGING
        korrnum          = lv_korrnum
        devclass         = lv_package    " Development class for Change and Transport Organizer
      EXCEPTIONS
        save_failure     = 1
        action_canceled  = 2
        OTHERS           = 3.

    IF sy-subrc <> 0.
      zcx_abapgit_exception=>raise( 'error from SXO_IMPL_SAVE' ).
    ENDIF.

    CALL FUNCTION 'SXO_IMPL_ACTIVE'
      EXPORTING
        imp_name                  = ls_impl-imp_name    " Implementation name for an enhancement
        no_dialog                 = abap_true
      EXCEPTIONS
        badi_not_existing         = 1
        imp_not_existing          = 2
        already_active            = 3
        data_inconsistency        = 4
        activation_not_admissable = 5
        action_canceled           = 6
        access_failure            = 7
        OTHERS                    = 8.

    IF sy-subrc <> 0.
      zcx_abapgit_exception=>raise( 'error from SXO_IMPL_ACTIVE' ).
    ENDIF.

  ENDMETHOD.

  METHOD lif_object~delete.

    DATA: lv_imp_name TYPE rsexscrn-imp_name.

    lv_imp_name = ms_item-obj_name.

    CALL FUNCTION 'SXO_IMPL_DELETE'
      EXPORTING
        imp_name           = lv_imp_name
        no_dialog          = abap_true
      EXCEPTIONS
        imp_not_existing   = 1
        action_canceled    = 2
        access_failure     = 3
        data_inconsistency = 4
        OTHERS             = 5.

    IF sy-subrc <> 0.
      zcx_abapgit_exception=>raise( 'error from SXO_IMPL_DELETE' ).
    ENDIF.

  ENDMETHOD.


  METHOD lif_object~jump.

    " SXO_IMPL_SHOW

    CALL FUNCTION 'RS_TOOL_ACCESS'
      EXPORTING
        operation           = 'SHOW'
        object_name         = ms_item-obj_name    " Object Name
        object_type         = ms_item-obj_type    " Object Type
        in_new_window       = abap_true
      EXCEPTIONS
        not_executed        = 1
        invalid_object_type = 2
        OTHERS              = 3.

    IF sy-subrc <> 0.
      zcx_abapgit_exception=>raise( 'error from RS_TOOL_ACCESS' ).
    ENDIF.

  ENDMETHOD.

  METHOD lif_object~compare_to_remote_version.

    CREATE OBJECT ro_comparison_result TYPE lcl_comparison_null.

  ENDMETHOD.

ENDCLASS.
