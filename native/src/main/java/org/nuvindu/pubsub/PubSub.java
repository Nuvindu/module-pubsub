// Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

package org.nuvindu.pubsub;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.Future;
import io.ballerina.runtime.api.Module;
import io.ballerina.runtime.api.PredefinedTypes;
import io.ballerina.runtime.api.async.Callback;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.StreamType;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BDecimal;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BTypedesc;

import static org.nuvindu.pubsub.Constants.AUTO_CREATE_TOPICS;
import static org.nuvindu.pubsub.Constants.CONSUME_STREAM_METHOD;
import static org.nuvindu.pubsub.Constants.ORGANIZATION;
import static org.nuvindu.pubsub.Constants.PIPE;
import static org.nuvindu.pubsub.Constants.PIPE_CLASS_NAME;
import static org.nuvindu.pubsub.Constants.TOPICS;
import static org.nuvindu.pubsub.utils.Utils.createError;

/**
 * Provides a message communication model with publish/subscribe APIs.
 */
public class PubSub {

    public static Object subscribe(Environment environment, BObject pubsub, BString topicName, int limit,
                                   BDecimal timeout, BTypedesc typeParam) {
        if ((pubsub.get(StringUtils.fromString(Constants.IS_CLOSED))).equals(true)) {
            return createError("Users cannot subscribe to a closed PubSub.");
        }
        BObject defaultPipe = pubsub.getObjectValue(StringUtils.fromString(PIPE));
        Module module = new Module(ORGANIZATION, PIPE, defaultPipe.getType().getPackage().getMajorVersion());
        BObject pipe = ValueCreator.createObjectValue(module, PIPE_CLASS_NAME, limit);
        if (!addSubscriber(pubsub, topicName, pipe)) {
            return createError("Topic '" + topicName + "' does not exist.");
        }
        Object[] arguments = new Object[]{timeout, true, typeParam, true};
        Future futureResult = environment.markAsync();
        StreamType streamType = TypeCreator.createStreamType(typeParam.getDescribingType(),
                TypeCreator.createUnionType(PredefinedTypes.TYPE_ERROR, PredefinedTypes.TYPE_NULL));
        environment.getRuntime()
                .invokeMethodAsyncConcurrently(pipe, CONSUME_STREAM_METHOD, null, null,
                                               new Callback() {
                                                    @Override
                                                    public void notifySuccess(Object result) {
                                                        futureResult.complete(result);
                                                    }

                                                    @Override
                                                    public void notifyFailure(BError bError) {
                                                        futureResult.complete(createError(bError.getMessage()));
                                                    }
                                               }, null, streamType, arguments);
        return null;
    }

    public static boolean addSubscriber(BObject pubsub, BString topicName, BObject pipe) {
        BMap topics = pubsub.getMapValue(StringUtils.fromString(TOPICS));
        boolean autoCreateTopics = pubsub.getBooleanValue(StringUtils.fromString(AUTO_CREATE_TOPICS));
        if (!topics.containsKey(topicName)) {
            if (!autoCreateTopics) {
                return false;
            }
            BArray pipes = ValueCreator.createArrayValue(TypeCreator.createArrayType(pipe.getType()));
            pipes.append(pipe);
            topics.put(topicName, pipes);
        } else {
            BArray pipes = (BArray) topics.get(topicName);
            pipes.append(pipe);
            topics.put(topicName, pipes);
        }
        return true;
    }
}
