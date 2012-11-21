<#include "/provider_macroses.ftl">
/* AUTO-GENERATED FILE.  DO NOT MODIFY.
 *
 * This class was automatically generated by the AnnotatedSQL library.
  */
package ${pkgName};

<#list imports as import>
import ${import};	 
</#list> 

import java.util.ArrayList;

import android.content.ContentProviderOperation;
import android.content.ContentProviderResult;
import android.content.OperationApplicationException;
import android.content.ContentProvider;
import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Context;
import android.content.UriMatcher;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;
import android.database.sqlite.SQLiteQueryBuilder;
import android.net.Uri;
import android.text.TextUtils;

public class ${className} extends ContentProvider{

	public static final String AUTHORITY = "${authority}";
	public static final String FRAGMENT_NO_NOTIFY = "no-notify";
	public static final String QUERY_LIMIT = "limit";
	public static final String QUERY_GROUP_BY = "groupBy";
	
	public static final Uri BASE_URI = Uri.parse("content://" + AUTHORITY);

	protected final static int MATCH_TYPE_ITEM = 0x0001;
	protected final static int MATCH_TYPE_DIR = 0x0002;
	protected final static int MATCH_TYPE_MASK = 0x000f;
	
	<#list entities as e>
	protected final static int MATCH_${getMathcName(e.path)} = ${e.codeHex};
	</#list>
	
	protected static final UriMatcher matcher = new UriMatcher(UriMatcher.NO_MATCH);

	static {
		<#list entities as e>
		matcher.addURI(AUTHORITY, ${e.path}, MATCH_${getMathcName(e.path)}); 
		</#list> 
	}
	
	protected SQLiteOpenHelper dbHelper;
	protected ContentResolver contentResolver;

	@Override
	public boolean onCreate() {
		final Context context = getContext();
		<#if generateHelper>
		dbHelper = new AnnotationSql(context);
		<#else>
		dbHelper = new ${openHelperClass}(context);
		</#if>
		contentResolver = context.getContentResolver();
		return true;
	}
	
	@Override
	public String getType(Uri uri) {
		final String type;
		switch (matcher.match(uri) & MATCH_TYPE_MASK) {
			case MATCH_TYPE_ITEM:
				type = ContentResolver.CURSOR_ITEM_BASE_TYPE + "/vnd." + AUTHORITY + ".item";
				break;
			case MATCH_TYPE_DIR:
				type = ContentResolver.CURSOR_DIR_BASE_TYPE + "/vnd." + AUTHORITY + ".dir";
				break;
			default:
				throw new IllegalArgumentException("Unsupported uri " + uri);
			}
		return type;
	}

	@Override
	public Cursor query(Uri uri, String[] projection, String selection, String[] selectionArgs, String sortOrder) {
		final SQLiteQueryBuilder query = new SQLiteQueryBuilder();
		switch (matcher.match(uri)) {
			<#list entities as e>
			case MATCH_${getMathcName(e.path)}:{
				query.setTables(${e.tableLink});
				<#if e.item>
				query.appendWhere("${e.selectColumn} = " + uri.getLastPathSegment());
				</#if>
				break;
			}
			</#list> 
			default:
				throw new IllegalArgumentException("Unsupported uri " + uri);
		}
		Cursor c = query.query(dbHelper.getReadableDatabase(),
        		projection, selection, selectionArgs,
        		uri.getQueryParameter(QUERY_GROUP_BY), null, sortOrder, uri.getQueryParameter(QUERY_LIMIT));
		c.setNotificationUri(getContext().getContentResolver(), uri);
		
		return c;
	}

<#if supportTransaction>
	@Override
	public ContentProviderResult[] applyBatch(ArrayList<ContentProviderOperation> operations) throws OperationApplicationException {
		SQLiteDatabase sql = dbHelper.getWritableDatabase();
		sql.beginTransaction();
		ContentProviderResult[] res = null;
		try{
			res = super.applyBatch(operations);
			sql.setTransactionSuccessful();
		}finally{
			sql.endTransaction();
		}
		return res;
	}

	
    @Override
    public int bulkInsert(Uri uri, ContentValues[] values) {
    	SQLiteDatabase sql = dbHelper.getWritableDatabase();
		sql.beginTransaction();
		int count = 0;
		try {
			count = super.bulkInsert(uri, values);
			sql.setTransactionSuccessful();
		} finally {
			sql.endTransaction();
		}
    	return count;
    }
</#if>

	@Override
	public Uri insert(Uri uri, ContentValues values) {
		String table;
		Uri alternativeNotify = null;
		
		switch(matcher.match(uri)){
			<#list entities as e>
			<#if !e.item && !e.onlyQuery>
			case MATCH_${getMathcName(e.path)}:{
				table = ${e.tableLink};
				<#if (e.altNotify?length > 0)>
				alternativeNotify = getContentUri("${e.altNotify}");
				</#if>
				break;
			}
			</#if>
			</#list> 
			default:
				throw new IllegalArgumentException("Unsupported uri " + uri);
		}
		<#list entities as e>
			<@addInsertBeforeTrigger uri=e />
		</#list>
		dbHelper.getWritableDatabase().insertWithOnConflict(table, null, values, SQLiteDatabase.CONFLICT_REPLACE);
		<#list entities as e>
			<@addInsertAfterTrigger uri=e />
		</#list>
		if(!ignoreNotify(uri)){
			contentResolver.notifyChange(uri, null);
			if(alternativeNotify != null){
				contentResolver.notifyChange(alternativeNotify, null);
			}
		}
		return uri;
	}
	
	@Override
	public int update(Uri uri, ContentValues values, String selection, String[] selectionArgs) {
		String table;
        String processedSelection = selection;
        Uri alternativeNotify = null;
        
		switch(matcher.match(uri)){
			<#list entities as e>
			<#if !e.onlyQuery>
			case MATCH_${getMathcName(e.path)}:{
				table = ${e.tableLink};
				<#if e.item>
				processedSelection = composeIdSelection(selection, uri.getLastPathSegment(), "${e.selectColumn}");
					<#if (e.altNotify?length > 0)>
				alternativeNotify = getContentUri("${e.altNotify}", uri.getLastPathSegment());
					</#if>
				<#elseif (e.altNotify?length > 0)>
				alternativeNotify = getContentUri("${e.altNotify}");
				</#if>
				break;
			}
			</#if>
			</#list> 
			default:
				throw new IllegalArgumentException("Unsupported uri " + uri);
		}
		<#list entities as e>
			<@addUpdateBeforeTrigger uri=e />
		</#list>
		int count = dbHelper.getWritableDatabase().update(table, values, processedSelection, selectionArgs);
		<#list entities as e>
			<@addUpdateAfterTrigger uri=e />
		</#list>
		if(!ignoreNotify(uri)){
			contentResolver.notifyChange(uri, null);
			if(alternativeNotify != null){
				contentResolver.notifyChange(alternativeNotify, null);
			}
		}
		
		return count;
	}
	
	@Override
	public int delete(Uri uri, String selection, String[] selectionArgs) {
		String table;
        String processedSelection = selection;
        Uri alternativeNotify = null;
        
		switch(matcher.match(uri)){
			<#list entities as e>
			<#if !e.onlyQuery>
			case MATCH_${getMathcName(e.path)}:{
				table = ${e.tableLink};
				<#if e.item>
				processedSelection = composeIdSelection(selection, uri.getLastPathSegment(), "${e.selectColumn}");
					<#if (e.altNotify?length > 0)>
				alternativeNotify = getContentUri("${e.altNotify}", uri.getLastPathSegment());
					</#if>
				<#elseif (e.altNotify?length > 0)>
				alternativeNotify = getContentUri("${e.altNotify}");
				</#if>
				break;
			}
			</#if>
			</#list> 
			default:
				throw new IllegalArgumentException("Unsupported uri " + uri);
		}
		<#list entities as e>
			<@addDeleteBeforeTrigger uri=e />
		</#list>
		int count = dbHelper.getWritableDatabase().delete(table, processedSelection, selectionArgs);
		<#list entities as e>
			<@addDeleteAfterTrigger uri=e />
		</#list>
		if(!ignoreNotify(uri)){
			contentResolver.notifyChange(uri, null);
			if(alternativeNotify != null){
				contentResolver.notifyChange(alternativeNotify, null);
			}
		}
		return count;
	}
	<#list entities as e>
		<#if e.triggered>
			<#list e.triggers as trigger>
				<#if trigger.insert && trigger.before>
			
	protected void on${trigger.methodName?cap_first}BeforeInserted(ContentValues values){
		
	}
				</#if>			
				<#if trigger.insert && trigger.after>
			
	protected void on${trigger.methodName?cap_first}AfterInserted(ContentValues values){
		
	}
				</#if>
			<#if trigger.delete && trigger.before>
			
	protected void on${trigger.methodName?cap_first}BeforeDeleted(Uri uri, String selection, String[] selectionArgs){
		
	}
			</#if>
			<#if trigger.delete && trigger.after>
			
	protected void on${trigger.methodName?cap_first}AfterDeleted(Uri uri, String selection, String[] selectionArgs){
		
	}
			</#if>
			<#if trigger.update && trigger.before>
			
	protected void on${trigger.methodName?cap_first}BeforeUpdated(Uri uri, ContentValues values, String selection, String[] selectionArg){
		
	}
			</#if>
			<#if trigger.update && trigger.after>
			
	protected void on${trigger.methodName?cap_first}AfterUpdated(Uri uri, ContentValues values, String selection, String[] selectionArg){
		
	}
			</#if>
			</#list>
		</#if>
	</#list>
		
	protected static boolean ignoreNotify(Uri uri){
		return FRAGMENT_NO_NOTIFY.equals(uri.getFragment());
	}
	
	protected String composeIdSelection(String originalSelection, String id, String idColumn) {
        StringBuffer sb = new StringBuffer();
        sb.append(idColumn).append('=').append(id);
        if (!TextUtils.isEmpty(originalSelection)) {
            sb.append(" AND (").append(originalSelection).append(')');
        }
        return sb.toString();
    }
 
 	public static Uri getContentUri(String path){
		if(TextUtils.isEmpty(path))
			return null;
		return BASE_URI.buildUpon().appendPath(path).build(); 
	}
	
	public static Uri getContentUriGroupBy(String path, String groupBy){
		if(TextUtils.isEmpty(path))
			return null;
		return BASE_URI.buildUpon().appendPath(path).appendQueryParameter(QUERY_GROUP_BY, groupBy).build(); 
	}
	
	public static Uri getContentUri(String path, long id){
		if(TextUtils.isEmpty(path))
			return null;
		return BASE_URI.buildUpon().appendPath(path).appendPath(String.valueOf(id)).build(); 
	}
	
	public static Uri getContentUri(String path, String id){
		if(TextUtils.isEmpty(path))
			return null;
		return BASE_URI.buildUpon().appendPath(path).appendPath(id).build(); 
	}
	
	public static Uri getContentWithLimitUri(String path, int limit){
		if(TextUtils.isEmpty(path))
			return null;
		return BASE_URI.buildUpon().appendPath(path).appendQueryParameter(QUERY_LIMIT, String.valueOf(limit)).build(); 
	}
	
	public static Uri getNoNotifyContentUri(String path){
		if(TextUtils.isEmpty(path))
			return null;
		return BASE_URI.buildUpon().appendPath(path).fragment(FRAGMENT_NO_NOTIFY).build(); 
	}
	
	public static Uri getNoNotifyContentUri(String path, long id){
		if(TextUtils.isEmpty(path))
			return null;
		return BASE_URI.buildUpon().appendPath(path).appendPath(String.valueOf(id)).fragment(FRAGMENT_NO_NOTIFY).build(); 
	}
	
	<#if generateHelper>   
	protected class AnnotationSql extends SQLiteOpenHelper {

		public AnnotationSql(Context context) {
			super(context, ${schemaClassName}.DB_NAME, null, ${schemaClassName}.DB_VERSION);
		}

		@Override
		public void onCreate(SQLiteDatabase db) {
			${schemaClassName}.onCreate(db);
		}

		@Override
		public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
			${schemaClassName}.onDrop(db);
			onCreate(db);
		}

	}
	</#if>

}