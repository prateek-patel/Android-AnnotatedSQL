package com.annotatedsql.processor.sql.view;

import java.util.List;

import javax.lang.model.element.Element;

import com.annotatedsql.ParserEnv;
import com.annotatedsql.annotation.sql.From;
import com.annotatedsql.ftl.ColumnMeta;
import com.annotatedsql.processor.sql.SimpleViewParser;

public class FromParser extends ViewTableColumnParser<FromResult, From>{

	public FromParser(ParserEnv parserEnv, SimpleViewParser parentParser, Element f) {
		super(parserEnv, parentParser, f, true);
	}

	@Override
	public FromResult parse() {
		List<ColumnMeta> columns = parseColumns();
		return new FromResult(aliasName, " FROM " + tableName + " AS " + aliasName, toSqlSelect(columns), columns);
	}

	@Override
	public Class<From> getAnnotationClass() {
		return From.class;
	}

	@Override
	public String parseTableName() {
		return annotation.value();
	}

}
