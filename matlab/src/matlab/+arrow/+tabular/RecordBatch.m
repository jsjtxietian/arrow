% Licensed to the Apache Software Foundation (ASF) under one or more
% contributor license agreements.  See the NOTICE file distributed with
% this work for additional information regarding copyright ownership.
% The ASF licenses this file to you under the Apache License, Version
% 2.0 (the "License"); you may not use this file except in compliance
% with the License.  You may obtain a copy of the License at
%
%   http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
% implied.  See the License for the specific language governing
% permissions and limitations under the License.

classdef RecordBatch < matlab.mixin.CustomDisplay & ...
                       matlab.mixin.Scalar
%arrow.tabular.RecordBatch A tabular data structure representing
% a set of arrow.array.Array objects with a fixed schema.

    properties (Dependent, SetAccess=private, GetAccess=public)
        NumColumns
        ColumnNames
    end

    properties (Hidden, SetAccess=private, GetAccess=public)
        Proxy
    end

    methods
        function obj = RecordBatch(proxy)
            arguments
                proxy(1, 1) libmexclass.proxy.Proxy {validate(proxy, "arrow.tabular.proxy.RecordBatch")}
            end
            import arrow.internal.proxy.validate
            obj.Proxy = proxy;
        end

        function numColumns = get.NumColumns(obj)
            numColumns = obj.Proxy.numColumns();
        end

        function columnNames = get.ColumnNames(obj)
            columnNames = obj.Proxy.columnNames();
        end

        function arrowArray = column(obj, idx)
            if ~isempty(idx) && isscalar(idx) && isnumeric(idx) && idx >= 1
                args = struct(Index=int32(idx));
                [proxyID, typeID] = obj.Proxy.getColumnByIndex(args);
                traits = arrow.type.traits.traits(arrow.type.ID(typeID));
                proxy = libmexclass.proxy.Proxy(Name=traits.ArrayProxyClassName, ID=proxyID);
                arrowArray = traits.ArrayConstructor(proxy);
            else
                errid = "arrow:tabular:recordbatch:UnsupportedColumnIndexType";
                msg = "Index must be a positive scalar integer.";
                error(errid, msg);
            end
        end

        function T = table(obj)
            numColumns = obj.NumColumns;
            matlabArrays = cell(1, numColumns);
            
            for ii = 1:numColumns
                arrowArray = obj.column(ii);
                matlabArrays{ii} = toMATLAB(arrowArray);
            end

            variableNames = matlab.lang.makeUniqueStrings(obj.ColumnNames);
            % NOTE: Does not currently handle edge cases like ColumnNames
            %       matching the table DimensionNames.
            T = table(matlabArrays{:}, VariableNames=variableNames);
        end

        function T = toMATLAB(obj)
            T = obj.table();
        end
    end

    methods (Access = private)
        function str = toString(obj)
            str = obj.Proxy.toString();
        end
    end

    methods (Access=protected)
        function displayScalarObject(obj)
            disp(obj.toString());
        end
    end
end
